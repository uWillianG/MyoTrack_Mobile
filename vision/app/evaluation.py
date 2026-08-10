"""A análise em si: do arquivo de vídeo ao resultado, sem HTTP e sem storage.

Mora fora do `main.py` para o harness de medição (`tools/evaluate.py`) rodar EXATAMENTE o que
o serviço roda. Enquanto isto era código de dentro do endpoint, medir exigia reescrever o
encadeamento — e harness que reimplementa o que mede não mede coisa nenhuma.
"""

from .analysis import MAX_CAMERA_FRONTALITY, MIN_POSE_COVERAGE, process_video
from .heuristics import HEURISTICS, compute_score


class UnsupportedExercise(Exception):
    """Exercício fora do catálogo de heurísticas."""


def evaluate(video_path: str, exercise: str, overlay_path: str | None = None) -> dict:
    """Analisa um vídeo local. Levanta `BusinessError` no que o usuário consegue corrigir."""
    heuristic = HEURISTICS.get(exercise)
    if heuristic is None:
        raise UnsupportedExercise(f"Exercício não suportado: {exercise}")

    extraction = process_video(video_path, overlay_path)
    result = heuristic(extraction.frames)

    if result.not_evaluable_reason is None and extraction.coverage < MIN_POSE_COVERAGE:
        result.not_evaluable_reason = (
            "Pose detectada em poucos frames — grave em um local iluminado, "
            "de lado e com o corpo inteiro no enquadramento.")

    # Vídeo de frente não é pego pela cobertura: a pose aparece em todos os frames, e é
    # justamente por isso que ele é perigoso. A projeção encurta todos os ângulos, e o
    # resultado sai como nota confiante e errada — que é pior que nota nenhuma quando o
    # usuário vai mudar como levanta peso por causa dela.
    if (result.not_evaluable_reason is None
            and extraction.frontality is not None
            and extraction.frontality > MAX_CAMERA_FRONTALITY):
        result.not_evaluable_reason = (
            "A câmera está de frente para você — grave de lado, com o corpo inteiro "
            "no enquadramento.")

    return {
        "score": compute_score(result),
        "rep_count": result.rep_count,
        "issues": [vars(issue) for issue in result.issues],
        "correct_points": [vars(point) for point in result.correct_points],
        "metrics": {
            **result.metrics,
            "duration_sec": round(extraction.duration, 1),
            "pose_coverage": round(extraction.coverage, 2),
            # Sai sempre, inclusive quando passa no corte: é o número que permite calibrar
            # MAX_CAMERA_FRONTALITY contra vídeos reais, em vez de contra a intuição de quem
            # o escolheu.
            "camera_frontality": (
                round(extraction.frontality, 2)
                if extraction.frontality is not None else None),
        },
        "not_evaluable_reason": result.not_evaluable_reason,
    }
