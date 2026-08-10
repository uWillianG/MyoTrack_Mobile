"""Extração de pose (MediaPipe) e sinais articulares por frame.

O vídeo é amostrado a ~12 fps — suficiente para exercícios de força e ~2,5x
mais barato que processar todos os frames de um vídeo 30 fps.
"""

import math
import os
import statistics
import subprocess
import tempfile
from dataclasses import dataclass

import cv2
import mediapipe as mp

MAX_DURATION_SEC = 60
TARGET_FPS = 12

# Fração mínima de frames com pose UTILIZÁVEL para o vídeo ser avaliável — frame em que a
# pessoa aparece encoberta não conta, ainda que o modelo tenha chutado landmarks nele.
MIN_POSE_COVERAGE = 0.5

# Visibilidade média mínima dos seis landmarks do lado analisado para o frame entrar na conta.
#
# Sem este corte, articulação encoberta virava ângulo mesmo assim: o MediaPipe sempre devolve
# uma posição, confiante ou não. E como as checagens leem extremos (o joelho mais fechado da
# repetição), bastava um frame chutado para uma repetição rasa passar por funda.
MIN_SIDE_VISIBILITY = 0.5

# Acima desta razão o vídeo está frontal demais para as heurísticas, que são todas de perfil.
# Conservador de propósito: recusa o que está claramente de frente, não o que está um pouco
# torto. Vídeo torto ainda vale mais que nenhum — vídeo de frente vale menos que nenhum,
# porque produz nota confiante e errada.
MAX_CAMERA_FRONTALITY = 0.75


class BusinessError(Exception):
    """Erro que o usuário consegue corrigir (vídeo longo demais, sem pessoa visível...)."""


@dataclass
class FrameSignals:
    t: float                # segundos desde o início
    knee_angle: float       # quadril-joelho-tornozelo
    hip_angle: float        # ombro-quadril-joelho
    elbow_angle: float      # ombro-cotovelo-punho
    trunk_angle: float      # inclinação do tronco vs. vertical (0 = ereto)
    hip_y: float            # coordenadas normalizadas de imagem (y cresce para baixo)
    knee_y: float
    shoulder_y: float
    wrist_y: float


@dataclass
class PoseExtraction:
    """O que `process_video` apurou sobre o vídeo.

    Virou objeto quando `frontality` entrou: uma tupla de quatro posições já exigia conferir a
    ordem no ponto de uso, e o quarto valor é justamente o que decide se a análise sai ou não.
    """
    frames: list[FrameSignals]
    coverage: float
    duration: float
    frontality: float | None


@dataclass
class _Sample:
    """Um frame amostrado, com os sinais dos DOIS lados ainda em aberto."""
    t: float
    sides: tuple[FrameSignals, FrameSignals]
    visibility: tuple[float, float]
    frontality: float | None


def _angle(a, b, c) -> float:
    """Ângulo em graus no vértice b, formado pelos pontos a-b-c.

    Aceita 2D ou 3D: os pontos vêm em 3D quando o MediaPipe devolve os landmarks métricos,
    e em pixels quando não devolve.
    """
    v1 = tuple(x - y for x, y in zip(a, b))
    v2 = tuple(x - y for x, y in zip(c, b))
    dot = sum(x * y for x, y in zip(v1, v2))
    n1 = math.sqrt(sum(x * x for x in v1))
    n2 = math.sqrt(sum(x * x for x in v2))
    if n1 < 1e-6 or n2 < 1e-6:
        return 180.0
    cos = max(-1.0, min(1.0, dot / (n1 * n2)))
    return math.degrees(math.acos(cos))


# Índices dos landmarks do BlazePose (33 pontos): [lado esquerdo, lado direito].
SHOULDER, ELBOW, WRIST, HIP, KNEE, ANKLE = (11, 12), (13, 14), (15, 16), (23, 24), (25, 26), (27, 28)


def _side_visibility(landmarks, side: int) -> float:
    ids = [SHOULDER[side], ELBOW[side], WRIST[side], HIP[side], KNEE[side], ANKLE[side]]
    return sum(landmarks[i].visibility for i in ids) / len(ids)


def _frontality(landmarks, width: int, height: int) -> float | None:
    """Quão de frente a câmera está: ~0,2 de perfil, ~0,9 de frente.

    Largura ombro-a-ombro dividida pelo comprimento do tronco, ambas em PIXELS. De lado os
    ombros se sobrepõem e a largura vira a espessura do tronco; de frente ela é quase o
    comprimento inteiro. O tronco serve de régua porque não encurta quando a pessoa gira em
    torno do próprio eixo — é o que torna a razão comparável entre corpos diferentes, e o
    que a faz valer também deitado (supino) ou em prancha (flexão).
    """
    p = lambda i: (landmarks[i].x * width, landmarks[i].y * height)
    left_shoulder, right_shoulder = p(SHOULDER[0]), p(SHOULDER[1])
    left_hip, right_hip = p(HIP[0]), p(HIP[1])

    midpoint = lambda a, b: ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    torso = math.dist(
        midpoint(left_shoulder, right_shoulder), midpoint(left_hip, right_hip))
    if torso < 1e-6:
        return None
    return math.dist(left_shoulder, right_shoulder) / torso


def _extract_signals(landmarks, world, side: int, t: float, width: int, height: int) -> FrameSignals:
    """Sinais de um frame, para um lado do corpo.

    Os ângulos articulares saem dos landmarks MÉTRICOS (`pose_world_landmarks`, em metros com
    origem no quadril), e não da imagem. A projeção 2D encurta o ângulo quando a câmera não
    está exatamente de lado, e esse erro é ENVIESADO, não ruído: sempre faz o agachamento
    parecer mais raso do que foi. Suavizar não tira viés — medir em 3D tira.
    """
    if world is not None:
        q = lambda i: (world[i].x, world[i].y, world[i].z)
    else:
        # Sem os pontos métricos, cai para pixels. Coordenadas normalizadas (0-1) não servem:
        # distorcem com a proporção da tela, e o mesmo movimento daria ângulos diferentes em
        # 16:9 e 9:16.
        q = lambda i: (landmarks[i].x * width, landmarks[i].y * height)

    shoulder, elbow, wrist = q(SHOULDER[side]), q(ELBOW[side]), q(WRIST[side])
    hip, knee, ankle = q(HIP[side]), q(KNEE[side]), q(ANKLE[side])

    # A inclinação do tronco fica na IMAGEM, e não nos pontos métricos: ela é medida contra a
    # vertical da CENA, que a imagem dá de graça (câmera em pé), enquanto o espaço 3D do
    # MediaPipe é reconstruído a cada frame com origem no quadril e não é referência confiável
    # de gravidade. O ruído de `z` entraria direto em `_trunk_stable`, que compara a AMPLITUDE
    # do tronco na repetição — o teste mais sensível a ruído de todos.
    shoulder_px = (landmarks[SHOULDER[side]].x * width, landmarks[SHOULDER[side]].y * height)
    hip_px = (landmarks[HIP[side]].x * width, landmarks[HIP[side]].y * height)
    dx, dy = shoulder_px[0] - hip_px[0], shoulder_px[1] - hip_px[1]
    trunk = math.degrees(math.atan2(abs(dx), abs(dy))) if abs(dy) > 1e-6 else 90.0

    # As posições verticais continuam normalizadas — as heurísticas comparam
    # y com y (ex.: quadril abaixo do joelho), então a escala é indiferente.
    y = lambda i: landmarks[i].y
    return FrameSignals(
        t=t,
        knee_angle=_angle(hip, knee, ankle),
        hip_angle=_angle(shoulder, hip, knee),
        elbow_angle=_angle(shoulder, elbow, wrist),
        trunk_angle=trunk,
        hip_y=y(HIP[side]),
        knee_y=y(KNEE[side]),
        shoulder_y=y(SHOULDER[side]),
        wrist_y=y(WRIST[side]),
    )


def _dominant_side(samples: list[_Sample]) -> int:
    """O lado voltado para a câmera, decidido UMA vez para o vídeo inteiro.

    Escolher quadro a quadro parecia mais esperto e era pior: perto do empate a visibilidade
    oscila, o sinal alterna entre perna esquerda e direita — que no afundo estão em ângulos
    bem diferentes — e a troca vira uma oscilação que não existiu no movimento. O detector de
    repetição conta oscilação, então isso saía como repetição a mais.
    """
    left = statistics.fmean(s.visibility[0] for s in samples)
    right = statistics.fmean(s.visibility[1] for s in samples)
    return 0 if left >= right else 1


def process_video(video_path: str, overlay_path: str | None) -> PoseExtraction:
    """Extrai sinais por frame e, opcionalmente, grava o vídeo com o esqueleto."""
    capture = cv2.VideoCapture(video_path)
    if not capture.isOpened():
        raise BusinessError("Não foi possível ler o vídeo. Use MP4, MOV ou WebM.")

    # Vídeos de celular em retrato vêm com frames deitados + metadado de rotação.
    # Garante que o OpenCV aplique a rotação (o default variou entre versões).
    capture.set(cv2.CAP_PROP_ORIENTATION_AUTO, 1)

    fps = capture.get(cv2.CAP_PROP_FPS) or 30.0
    total_frames = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    duration = total_frames / fps if fps > 0 else 0.0
    if duration > MAX_DURATION_SEC:
        capture.release()
        raise BusinessError(f"Vídeo com {duration:.0f}s — o limite é {MAX_DURATION_SEC}s. Grave apenas a série.")

    step = max(1, round(fps / TARGET_FPS))
    effective_fps = fps / step

    # O writer é criado a partir do PRIMEIRO frame lido: com rotação automática,
    # CAP_PROP_FRAME_WIDTH/HEIGHT podem reportar as dimensões sem rotação — e o
    # VideoWriter descarta silenciosamente frames de tamanho diferente.
    writer = None
    raw_overlay = tempfile.mktemp(suffix=".mp4") if overlay_path is not None else None

    drawing = mp.solutions.drawing_utils
    pose_connections = mp.solutions.pose.POSE_CONNECTIONS

    samples: list[_Sample] = []
    sampled = 0
    with mp.solutions.pose.Pose(model_complexity=1, min_detection_confidence=0.5) as pose:
        index = 0
        while True:
            ok, frame = capture.read()
            if not ok:
                break
            if index % step != 0:
                index += 1
                continue
            index += 1
            sampled += 1
            t = (index - 1) / fps

            frame_height, frame_width = frame.shape[:2]
            if raw_overlay is not None and writer is None:
                writer = cv2.VideoWriter(
                    raw_overlay, cv2.VideoWriter_fourcc(*"mp4v"), effective_fps,
                    (frame_width, frame_height))

            result = pose.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            if result.pose_landmarks:
                landmarks = result.pose_landmarks.landmark
                world = (result.pose_world_landmarks.landmark
                         if result.pose_world_landmarks else None)
                # Os dois lados são calculados agora e a escolha fica para o fim do vídeo,
                # quando dá para olhar a série inteira. Custa duas contas de ângulo por frame,
                # irrelevante ao lado da estimativa de pose.
                samples.append(_Sample(
                    t=t,
                    sides=tuple(
                        _extract_signals(landmarks, world, side, t, frame_width, frame_height)
                        for side in (0, 1)),
                    visibility=tuple(_side_visibility(landmarks, side) for side in (0, 1)),
                    frontality=_frontality(landmarks, frame_width, frame_height),
                ))
                if writer is not None:
                    drawing.draw_landmarks(frame, result.pose_landmarks, pose_connections)
            if writer is not None:
                writer.write(frame)

    capture.release()
    if writer is not None:
        writer.release()
        _transcode_h264(raw_overlay, overlay_path)
        os.unlink(raw_overlay)

    if sampled == 0:
        raise BusinessError("Vídeo vazio ou corrompido.")
    if not samples:
        raise BusinessError(
            "Não foi possível detectar uma pessoa no vídeo. Grave de lado, com o corpo inteiro no enquadramento.")

    side = _dominant_side(samples)
    frames = [s.sides[side] for s in samples if s.visibility[side] >= MIN_SIDE_VISIBILITY]
    if not frames:
        raise BusinessError(
            "O corpo aparece encoberto ou cortado no vídeo inteiro. Grave de lado, com o corpo inteiro no enquadramento.")

    frontalities = [s.frontality for s in samples if s.frontality is not None]
    return PoseExtraction(
        frames=frames,
        coverage=len(frames) / sampled,
        duration=duration,
        # Mediana, e não média: basta um frame com os ombros mal estimados para a média subir.
        frontality=statistics.median(frontalities) if frontalities else None,
    )


def _transcode_h264(source: str, destination: str) -> None:
    """OpenCV grava MPEG-4 Part 2, que browsers não reproduzem — transcodifica para H.264."""
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", source,
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart", destination],
        check=True,
    )
