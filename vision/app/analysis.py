"""Extração de pose (MediaPipe) e sinais articulares por frame.

O vídeo é amostrado a ~12 fps — suficiente para exercícios de força e ~2,5x
mais barato que processar todos os frames de um vídeo 30 fps.

Amostrar assim já foi suspeito de estragar o rastreamento do MediaPipe, que assume frames
consecutivos. Medido em vídeo real, não estraga: processar TODOS os frames deixou o esqueleto
igual ou pior (teleporte mediano 0,0073 contra 0,0064 no leg press; 0,049 contra 0,037 na
rosca). O que ajuda de verdade é o rastreamento existir — `static_image_mode=True`, que roda o
detector em cada frame sem histórico, piora tudo em 5x.
"""

import math
import os
import statistics
import subprocess
import tempfile
from dataclasses import dataclass, field

import cv2
import mediapipe as mp

MAX_DURATION_SEC = 60
TARGET_FPS = 12

# Fração mínima de frames com pose UTILIZÁVEL para o vídeo ser avaliável — frame em que a
# pessoa aparece encoberta não conta, ainda que o modelo tenha chutado landmarks nele.
MIN_POSE_COVERAGE = 0.5

# Visibilidade mínima, na articulação MENOS visível das que o exercício lê, para o frame entrar
# na conta.
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


# Índices dos landmarks do BlazePose (33 pontos): [lado esquerdo, lado direito].
JOINTS: dict[str, tuple[int, int]] = {
    "shoulder": (11, 12), "elbow": (13, 14), "wrist": (15, 16),
    "hip": (23, 24), "knee": (25, 26), "ankle": (27, 28),
}

SHOULDER, ELBOW, WRIST = JOINTS["shoulder"], JOINTS["elbow"], JOINTS["wrist"]
HIP, KNEE, ANKLE = JOINTS["hip"], JOINTS["knee"], JOINTS["ankle"]

# As cadeias de ossos, na ordem em que as articulações se ligam. Servem para dois fins: ligar
# os pontos no desenho, e saber que segmentos têm comprimento FIXO — coisa que o corpo garante
# e o modelo não, o que faz disso uma medida de erro que dispensa gabarito.
_CHAINS = (("shoulder", "elbow", "wrist"), ("hip", "knee", "ankle"), ("shoulder", "hip"))

# Cores BGR do overlay. Verde é o frame que ENTROU na análise; cinza é o que o modelo viu e a
# análise descartou por visibilidade baixa. Distingui-los é o que transforma "o esqueleto se
# perdeu" em "o esqueleto se perdeu e o sistema sabia disso" — sem isso, um frame ruim desenhado
# com a mesma confiança de um bom faz a análise inteira parecer chute.
_COUNTED_COLOR = (0, 210, 0)
_DISCARDED_COLOR = (150, 150, 150)


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
    segment_cv: float | None = None


@dataclass
class _Sample:
    """Um frame amostrado, com os sinais dos DOIS lados ainda em aberto."""
    index: int
    t: float
    sides: tuple[FrameSignals, FrameSignals]
    visibility: tuple[float, float]
    frontality: float | None
    # Pixels das articulações desenháveis, por lado — guardados para o overlay, que só pode ser
    # desenhado depois que o vídeo inteiro decidiu qual lado analisar.
    points: tuple[dict, dict] = field(default_factory=lambda: ({}, {}))
    lengths: tuple[dict, dict] = field(default_factory=lambda: ({}, {}))


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


def _side_visibility(landmarks, side: int, joints) -> float:
    """A MENOR visibilidade entre as articulações que a análise vai ler.

    Era a média das seis, e a média escondia o pior justamente onde ele importa. No vídeo de
    rosca desta calibração, o ombro (0,997) e o quadril (0,970) sustentavam a média em 0,74
    enquanto o punho ficava em 0,75 e caía a 0,18 nos frames ruins — e o ângulo do cotovelo
    precisa dos TRÊS pontos. Ler o mínimo é dizer que quem decide é o elo mais fraco.

    `joints` também é o que impede o oposto: exigir do vídeo de rosca um tornozelo que ninguém
    lê. Ali o tornozelo é invenção (97% dos frames abaixo de 0,5, 41% fora do enquadramento) e
    entrava na média mesmo assim, ora contaminando-a, ora sendo salvo por ela.
    """
    return min(landmarks[JOINTS[name][side]].visibility for name in joints)


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
    está exatamente de lado, e esse erro TROCA DE SINAL conforme a pose: no fundo do agachamento
    ela fecha o ângulo, na perna estendida ela abre. Erro que muda de sentido dentro da mesma
    repetição não é compensável por limiar — medir em 3D é o que resolve.
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
    # de gravidade. O ruído de `z` entraria direto em `_trunk_range`, que compara a AMPLITUDE
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


def skeleton(joints) -> tuple[list[str], list[tuple[str, str]]]:
    """As articulações a desenhar e os ossos que as ligam, a partir do que a análise lê.

    Desenhar as 33 landmarks do BlazePose era a maior fonte de "o esqueleto está perdido", e na
    maior parte das vezes o esqueleto não estava: estava desenhando coisa que ninguém pediu. No
    vídeo de rosca desta calibração, enquadrado do peito para cima, o MediaPipe inventa quadril,
    joelho e tornozelo fora do quadro — e os inventa com CONVICÇÃO (quadril a 0,97 de
    visibilidade), então nem o filtro do próprio mediapipe, que corta em 0,5, os segura. O
    braço, que é o que a rosca lê, estava sendo rastreado direito o tempo todo, embaixo de um
    emaranhado de pernas imaginárias e de um lado do corpo que a análise nunca olhou.

    Articulação INTERMEDIÁRIA entra no desenho mesmo sem ser lida — na elevação frontal o sinal
    é ombro-punho, e ligar os dois direto desenharia um osso que não existe. Ela entra só para o
    traço fazer sentido anatômico; quem manda no corte de visibilidade continua sendo `joints`.
    """
    drawn = set(joints)
    for chain in _CHAINS:
        present = [i for i, name in enumerate(chain) if name in joints]
        if len(present) > 1:
            drawn.update(chain[present[0]:present[-1] + 1])
    edges = [(a, b) for chain in _CHAINS for a, b in zip(chain, chain[1:])
             if a in drawn and b in drawn]
    return sorted(drawn), edges


def _segment_cv(samples: list[_Sample], side: int, edges) -> float | None:
    """O quanto o osso mais inconstante mudou de comprimento ao longo do vídeo.

    O fêmur não encolhe. Se a distância quadril-joelho varia 10% de um frame para outro, não foi
    o corpo que mudou — foi o modelo que errou, e dá para afirmar isso sem gabarito humano
    nenhum. É a única medida de precisão aqui que não depende de alguém assistir ao vídeo e
    dizer o que era certo, e por isso é a que serve para comparar modelos e calibrações.

    Sai como métrica, e não como recusa: quanto é "alto demais" só um corpus responde. Nos dois
    vídeos medidos até aqui, a canela ficou em 0,095 no modelo atual e 0,041 no pesado.
    """
    worst = None
    for a, b in edges:
        lengths = [s.lengths[side][(a, b)] for s in samples if (a, b) in s.lengths[side]]
        if len(lengths) < 3:
            continue
        mean = statistics.fmean(lengths)
        if mean < 1e-6:
            continue
        cv = statistics.pstdev(lengths) / mean
        worst = cv if worst is None else max(worst, cv)
    return round(worst, 3) if worst is not None else None


def _read_pose(video_path: str, joints, drawn, edges):
    """Primeira passada: roda o MediaPipe e guarda sinais, visibilidade e pixels por frame."""
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
        raise BusinessError(
            f"Vídeo com {duration:.0f}s — o limite é {MAX_DURATION_SEC}s. Grave apenas a série.")

    step = max(1, round(fps / TARGET_FPS))
    samples: list[_Sample] = []
    sampled: list[int] = []
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
            sampled.append(index - 1)
            t = (index - 1) / fps

            frame_height, frame_width = frame.shape[:2]
            result = pose.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            if not result.pose_landmarks:
                continue

            landmarks = result.pose_landmarks.landmark
            world = (result.pose_world_landmarks.landmark
                     if result.pose_world_landmarks else None)
            # Os dois lados são calculados agora e a escolha fica para o fim do vídeo,
            # quando dá para olhar a série inteira. Custa duas contas de ângulo por frame,
            # irrelevante ao lado da estimativa de pose.
            samples.append(_Sample(
                index=index - 1,
                t=t,
                sides=tuple(
                    _extract_signals(landmarks, world, side, t, frame_width, frame_height)
                    for side in (0, 1)),
                visibility=tuple(
                    _side_visibility(landmarks, side, joints) for side in (0, 1)),
                frontality=_frontality(landmarks, frame_width, frame_height),
                points=tuple(
                    {name: (int(landmarks[JOINTS[name][side]].x * frame_width),
                            int(landmarks[JOINTS[name][side]].y * frame_height))
                     for name in drawn}
                    for side in (0, 1)),
                lengths=tuple(
                    {(a, b): math.dist(
                        (world[JOINTS[a][side]].x, world[JOINTS[a][side]].y,
                         world[JOINTS[a][side]].z),
                        (world[JOINTS[b][side]].x, world[JOINTS[b][side]].y,
                         world[JOINTS[b][side]].z))
                     for a, b in edges} if world else {}
                    for side in (0, 1)),
            ))

    capture.release()
    return samples, sampled, duration, fps / step


def _draw(frame, points, edges, counted: bool) -> None:
    color = _COUNTED_COLOR if counted else _DISCARDED_COLOR
    thickness = 3 if counted else 1
    for a, b in edges:
        if a in points and b in points:
            cv2.line(frame, points[a], points[b], color, thickness)
    for point in points.values():
        cv2.circle(frame, point, 5 if counted else 3, color, -1)


def _write_overlay(video_path: str, overlay_path: str, samples: list[_Sample], sampled: list[int],
                   side: int, counted: set, edges, fps: float) -> None:
    """Segunda passada: redesenha o vídeo com o esqueleto que a análise de fato usou.

    Duas passadas porque o lado analisado só se conhece no fim da primeira — e desenhar os dois
    lados era metade do emaranhado. A segunda passada não roda o MediaPipe de novo: só decodifica
    o vídeo e desenha pontos já calculados, o que custa uns poucos segundos contra os ~15 da
    estimativa de pose.

    Todo frame AMOSTRADO é escrito, tenha havido pose ou não — o overlay é o vídeo do usuário,
    e frame sumido viraria um salto na imagem que ele leria como travamento.
    """
    capture = cv2.VideoCapture(video_path)
    if not capture.isOpened():
        return
    capture.set(cv2.CAP_PROP_ORIENTATION_AUTO, 1)

    wanted = set(sampled)
    by_index = {s.index: s for s in samples}
    writer = None
    raw_overlay = tempfile.mktemp(suffix=".mp4")
    index = 0
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        if index not in wanted:
            index += 1
            continue
        index += 1

        frame_height, frame_width = frame.shape[:2]
        if writer is None:
            # O writer nasce do PRIMEIRO frame lido: com rotação automática,
            # CAP_PROP_FRAME_WIDTH/HEIGHT podem reportar as dimensões sem rotação — e o
            # VideoWriter descarta silenciosamente frames de tamanho diferente.
            writer = cv2.VideoWriter(
                raw_overlay, cv2.VideoWriter_fourcc(*"mp4v"), fps,
                (frame_width, frame_height))

        sample = by_index.get(index - 1)
        if sample is not None:
            _draw(frame, sample.points[side], edges, sample.index in counted)
        writer.write(frame)

    capture.release()
    if writer is not None:
        writer.release()
        _transcode_h264(raw_overlay, overlay_path)
        os.unlink(raw_overlay)


def process_video(video_path: str, overlay_path: str | None, joints) -> PoseExtraction:
    """Extrai sinais por frame e, opcionalmente, grava o vídeo com o esqueleto.

    `joints` são as articulações que o exercício lê (`ExerciseSpec.joints`). Elas decidem duas
    coisas: qual frame tem visibilidade suficiente para virar sinal, e o que o overlay desenha.
    """
    drawn, edges = skeleton(joints)
    samples, sampled, duration, effective_fps = _read_pose(video_path, joints, drawn, edges)

    if not sampled:
        raise BusinessError("Vídeo vazio ou corrompido.")
    if not samples:
        raise BusinessError(
            "Não foi possível detectar uma pessoa no vídeo. "
            "Grave de lado, com o corpo inteiro no enquadramento.")

    side = _dominant_side(samples)
    counted = [s for s in samples if s.visibility[side] >= MIN_SIDE_VISIBILITY]

    if overlay_path is not None:
        _write_overlay(video_path, overlay_path, samples, sampled, side,
                       {s.index for s in counted}, edges, effective_fps)

    if not counted:
        raise BusinessError(
            "O corpo aparece encoberto ou cortado no vídeo inteiro. "
            "Grave de lado, com o corpo inteiro no enquadramento.")

    frontalities = [s.frontality for s in samples if s.frontality is not None]
    return PoseExtraction(
        frames=[s.sides[side] for s in counted],
        coverage=len(counted) / len(sampled),
        duration=duration,
        # Mediana, e não média: basta um frame com os ombros mal estimados para a média subir.
        frontality=statistics.median(frontalities) if frontalities else None,
        segment_cv=_segment_cv(counted, side, edges),
    )


def _transcode_h264(source: str, destination: str) -> None:
    """OpenCV grava MPEG-4 Part 2, que browsers não reproduzem — transcodifica para H.264."""
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", source,
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart", destination],
        check=True,
    )
