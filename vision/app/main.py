"""Serviço vision: análise de execução de exercício por vídeo (MediaPipe Pose).

Sobe pelo `docker-compose.yml` da raiz. O único cliente é o `ExerciseVideoHandler` do Worker,
que fala com ele por `MYOTRACK_VISION_BASE_URL` (`http://localhost:8000` em desenvolvimento).

Vídeo não trafega por aqui: o serviço lê o original e grava o overlay **direto no MinIO**, com
as mesmas credenciais do backend. O que a API manda são chaves de objeto — um vídeo de série
ida e volta seriam dezenas de MB de tráfego interno sem propósito.

Este módulo é só o transporte. A análise mora em `evaluation.py`, para o harness de medição
poder rodar o mesmo caminho sem storage nem HTTP.
"""

import logging
import os
import tempfile

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from . import storage
from .analysis import BusinessError
from .evaluation import evaluate
from .heuristics import HEURISTICS

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("vision")

app = FastAPI(title="MyoTrack Vision", version="1.0")


class AnalyzeRequest(BaseModel):
    media_key: str
    exercise: str
    overlay_key: str | None = None


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/analyze")
def analyze(request: AnalyzeRequest):
    # Conferido ANTES do download: não vale baixar dezenas de MB para recusar o exercício.
    if request.exercise not in HEURISTICS:
        raise HTTPException(400, f"Exercício não suportado: {request.exercise}")

    suffix = os.path.splitext(request.media_key)[1] or ".mp4"
    video_path = tempfile.mktemp(suffix=suffix)
    overlay_path = tempfile.mktemp(suffix=".mp4") if request.overlay_key else None
    try:
        try:
            storage.download(request.media_key, video_path)
        except Exception:
            raise HTTPException(400, "Vídeo não encontrado no storage.")

        logger.info("Analisando %s (%s)", request.media_key, request.exercise)
        try:
            result = evaluate(video_path, request.exercise, overlay_path)
        except BusinessError as error:
            raise HTTPException(400, str(error))

        overlay_key = None
        if overlay_path is not None and os.path.exists(overlay_path):
            storage.upload(overlay_path, request.overlay_key, "video/mp4")
            overlay_key = request.overlay_key

        return {**result, "overlay_key": overlay_key}
    finally:
        for path in (video_path, overlay_path):
            if path and os.path.exists(path):
                os.unlink(path)
