"""Testa a extração de pose com cv2 e mediapipe falsos.

`test_heuristics.py` começa no `FrameSignals`: prova que as heurísticas são coerentes com o
sinal que recebem e, por construção, não vê nada do que vem antes. Só que é antes que mora
quase toda a imprecisão — índice de landmark trocado, lado alternando no meio da série, ângulo
lido da projeção em vez do espaço métrico. Nada disso aparecia em teste nenhum.

Aqui os landmarks são construídos com geometria conhecida: a perna é montada COM o ângulo de
joelho pedido, então dá para afirmar que o valor extraído é o valor certo — e não apenas que
ele é estável.
"""

import math
import sys
import types
from dataclasses import dataclass
from pathlib import Path

VISION = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(VISION))

WIDTH, HEIGHT = 720, 1280
SCALE = 600.0          # pixels por metro
CX, CY = 360.0, 1100.0

# O vídeo falso roda a 12 fps de propósito: é o TARGET_FPS do serviço, então o passo de
# amostragem é 1 e cada frame vira exatamente uma chamada ao mediapipe.
FPS = 12.0


# --- Dublês de cv2 e mediapipe ------------------------------------------------

@dataclass
class Landmark:
    x: float
    y: float
    z: float
    visibility: float


class FakeFrame:
    def __init__(self, height: int, width: int):
        self.shape = (height, width, 3)


class PoseResult:
    def __init__(self, image_landmarks, world_landmarks):
        self.pose_landmarks = (
            None if image_landmarks is None
            else types.SimpleNamespace(landmark=image_landmarks))
        self.pose_world_landmarks = (
            None if world_landmarks is None
            else types.SimpleNamespace(landmark=world_landmarks))


class Driver:
    """O vídeo falso: o que o mediapipe devolve para cada frame, e os metadados do arquivo."""

    def __init__(self, results, fps=FPS, opened=True, frame_count=None,
                 width=WIDTH, height=HEIGHT):
        self.results = results
        self.fps = fps
        self.opened = opened
        self.frames = [FakeFrame(height, width) for _ in results]
        self.frame_count = len(results) if frame_count is None else frame_count
        self.processed = 0
        self.writer = None
        self.released = False
        self.lines = []
        self.circles = []


DRIVER: Driver | None = None


class FakeCapture:
    def __init__(self, driver):
        self._driver = driver
        self._index = 0
        self.props = {}

    def isOpened(self):
        return self._driver.opened

    def set(self, prop, value):
        self.props[prop] = value

    def get(self, prop):
        if prop == cv2.CAP_PROP_FPS:
            return self._driver.fps
        if prop == cv2.CAP_PROP_FRAME_COUNT:
            return self._driver.frame_count
        return 0

    def read(self):
        if self._index >= len(self._driver.frames):
            return False, None
        frame = self._driver.frames[self._index]
        self._index += 1
        return True, frame

    def release(self):
        self._driver.released = True


class FakeWriter:
    def __init__(self, path, fourcc, fps, size):
        self.size = size
        self.written = 0
        # O serviço apaga este arquivo depois de transcodificar. Criá-lo evita um
        # FileNotFoundError e mantém o teste no assunto: as dimensões do writer.
        Path(path).write_bytes(b"")

    def write(self, frame):
        self.written += 1

    def release(self):
        pass


class FakePose:
    def __init__(self, **kwargs):
        FakePose.last_kwargs = kwargs

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def process(self, image):
        result = DRIVER.results[DRIVER.processed]
        DRIVER.processed += 1
        return result


cv2 = types.ModuleType("cv2")
cv2.CAP_PROP_FPS = 5
cv2.CAP_PROP_FRAME_COUNT = 7
cv2.CAP_PROP_ORIENTATION_AUTO = 48
cv2.COLOR_BGR2RGB = 4
cv2.cvtColor = lambda frame, code: frame
cv2.VideoCapture = lambda path: FakeCapture(DRIVER)
cv2.VideoWriter_fourcc = lambda *chars: 0


# O esqueleto é desenhado com cv2 direto, e não pelo drawing_utils do mediapipe: o desenho é um
# SUBCONJUNTO das landmarks (só o lado analisado, só as articulações que o exercício lê), e o
# drawing_utils desenha a lista inteira com um corte de visibilidade próprio, fixo em 0,5.
# Registrar cada traço deixa o teste afirmar o que foi parar na tela.
def _record_line(frame, start, end, color, thickness):
    DRIVER.lines.append((start, end, color))


def _record_circle(frame, center, radius, color, fill):
    DRIVER.circles.append((center, color))


cv2.line = _record_line
cv2.circle = _record_circle


def _make_writer(path, fourcc, fps, size):
    DRIVER.writer = FakeWriter(path, fourcc, fps, size)
    return DRIVER.writer


cv2.VideoWriter = _make_writer
sys.modules["cv2"] = cv2

mediapipe = types.ModuleType("mediapipe")
mediapipe.solutions = types.SimpleNamespace(pose=types.SimpleNamespace(Pose=FakePose))
sys.modules["mediapipe"] = mediapipe

from app import analysis  # noqa: E402
from app.analysis import BusinessError  # noqa: E402
from app.evaluation import evaluate  # noqa: E402

# O overlay é transcodificado por ffmpeg, que não existe aqui e não é o que se está testando.
analysis.subprocess = types.SimpleNamespace(run=lambda *a, **k: None)


# --- Geometria: um corpo construído a partir de ângulos conhecidos -------------

SEGMENT = 0.42   # coxa e canela, em metros
TORSO = 0.45     # quadril a ombro

# Meia-largura do corpo em cada articulação: ombros mais largos que quadris, como gente.
HALF_WIDTH = {"shoulder": 0.20, "elbow": 0.20, "wrist": 0.20,
              "hip": 0.10, "knee": 0.10, "ankle": 0.10}

# Os mesmos índices do BlazePose que `analysis.py` usa: [lado 0, lado 1].
INDEX = {"shoulder": (11, 12), "elbow": (13, 14), "wrist": (15, 16),
         "hip": (23, 24), "knee": (25, 26), "ankle": (27, 28)}


def body(knee_angle_deg, trunk_lean_deg=12.0):
    """Um corpo no plano sagital, em metros: u para a frente, v para cima.

    A canela aponta para baixo a partir do joelho e a coxa é girada `knee_angle_deg` a partir
    dela, para trás — então o ângulo quadril-joelho-tornozelo é exatamente o pedido. O tronco
    sai do quadril com a inclinação pedida em relação à vertical.
    """
    knee_angle = math.radians(knee_angle_deg)
    knee = (0.0, 0.50)
    ankle = (0.0, 0.50 - SEGMENT)
    hip = (knee[0] - SEGMENT * math.sin(knee_angle),
           knee[1] - SEGMENT * math.cos(knee_angle))

    lean = math.radians(trunk_lean_deg)
    shoulder = (hip[0] + TORSO * math.sin(lean), hip[1] + TORSO * math.cos(lean))
    elbow = (shoulder[0] + 0.05, shoulder[1] - 0.28)
    wrist = (elbow[0] + 0.05, elbow[1] - 0.26)

    return {"hip": hip, "knee": knee, "ankle": ankle,
            "shoulder": shoulder, "elbow": elbow, "wrist": wrist}


def make_pose(near, camera_deg=0.0, far=None, visibility=(0.95, 0.40), weak=None):
    """Landmarks de imagem e métricos de uma pose.

    A câmera gira `camera_deg` em torno do eixo vertical: 0 é o perfil, 90 é de frente. A
    imagem é a projeção ortográfica disso; os landmarks métricos guardam o corpo como ele é.

    `weak` sobrescreve a visibilidade de articulações específicas do lado 0 — é o que permite
    montar o caso que motivou o corte pelo mínimo: uma articulação péssima escondida atrás de
    outras ótimas.
    """
    far = near if far is None else far
    weak = weak or {}
    camera = math.radians(camera_deg)
    image = [Landmark(0.5, 0.5, 0.0, 0.0) for _ in range(33)]
    world = [Landmark(0.0, 0.0, 0.0, 0.0) for _ in range(33)]

    for side, joints in ((0, near), (1, far)):
        for name, (u, v) in joints.items():
            w = HALF_WIDTH[name] * (1 if side == 0 else -1)
            x = (u * math.cos(camera) + w * math.sin(camera)) * SCALE + CX
            y = -v * SCALE + CY
            index = INDEX[name][side]
            seen = weak.get(name, visibility[side]) if side == 0 else visibility[side]
            image[index] = Landmark(x / WIDTH, y / HEIGHT, 0.0, seen)
            world[index] = Landmark(u, v, w, seen)

    return image, world


def angle_2d(a, b, c):
    """O ângulo em b, calculado aqui do zero — não vale conferir o código com ele mesmo."""
    v1 = (a[0] - b[0], a[1] - b[1])
    v2 = (c[0] - b[0], c[1] - b[1])
    dot = v1[0] * v2[0] + v1[1] * v2[1]
    return math.degrees(math.acos(
        max(-1.0, min(1.0, dot / (math.hypot(*v1) * math.hypot(*v2))))))


def projected(joints, camera_deg):
    """Os mesmos pontos como a câmera os vê: só o eixo de profundidade encurta."""
    cos = math.cos(math.radians(camera_deg))
    return {name: (u * cos, v) for name, (u, v) in joints.items()}


# As articulações que o agachamento lê — o que a maioria dos testes daqui exercita.
SQUAT_JOINTS = ("shoulder", "hip", "knee", "ankle")


def run_video(results, overlay=None, joints=SQUAT_JOINTS, **driver):
    global DRIVER
    DRIVER = Driver(results, **driver)
    return analysis.process_video("fake.mp4", overlay, joints)


def still(joints, frames=6, camera_deg=0.0, **pose):
    """Um vídeo parado: a mesma pose repetida."""
    image, world = make_pose(joints, camera_deg=camera_deg, **pose)
    return [PoseResult(image, world) for _ in range(frames)]


# --- Verificação ---------------------------------------------------------------

ok = True


def check(name, condition, detail=""):
    global ok
    print(f"[{'OK ' if condition else 'FALHOU'}] {name} {detail}")
    ok &= bool(condition)
    return condition


def close(actual, expected, tol=0.5):
    return actual is not None and abs(actual - expected) <= tol


def raises(fn):
    try:
        fn()
    except BusinessError as error:
        return str(error)
    return None


# --- Ângulos: o valor extraído é o valor que se pôs no corpo -------------------

SQUAT = body(85.0)
extraction = run_video(still(SQUAT, camera_deg=40.0))
expected_knee = angle_2d(SQUAT["hip"], SQUAT["knee"], SQUAT["ankle"])
check("angulo do joelho sai do espaco metrico, nao da imagem",
      close(extraction.frames[0].knee_angle, expected_knee),
      f"(lido={extraction.frames[0].knee_angle:.2f}, esperado={expected_knee:.2f})")
check("o corpo foi montado com 85 graus e 85 graus saem", close(expected_knee, 85.0, 0.01))

# Sem os pontos métricos, a leitura cai para a projeção — e a projeção mente.
image_only = [PoseResult(p.pose_landmarks.landmark, None)
              for p in still(SQUAT, camera_deg=40.0)]
flat = run_video(image_only)
squat_projected = angle_2d(*(projected(SQUAT, 40.0)[j] for j in ("hip", "knee", "ankle")))
check("sem landmarks metricos, cai para a projecao em pixels",
      close(flat.frames[0].knee_angle, squat_projected),
      f"(lido={flat.frames[0].knee_angle:.2f}, projetado={squat_projected:.2f})")

# E aqui está o motivo de medir em 3D, que é mais forte do que "a projeção erra": o erro TROCA
# DE SINAL conforme a pose. No fundo do agachamento a projeção fecha o ângulo — a coxa está
# quase horizontal, e encurtar a profundidade a puxa para junto da canela. Na perna estendida
# ela abre. Erro que muda de sentido no meio da própria repetição não é compensável por
# limiar: nenhum número fixo conserta as duas pontas.
STANDING = body(172.0)
standing_true = angle_2d(STANDING["hip"], STANDING["knee"], STANDING["ankle"])
standing_projected = angle_2d(*(projected(STANDING, 40.0)[j] for j in ("hip", "knee", "ankle")))
check("no fundo do agachamento a projecao FECHA o angulo", squat_projected < expected_knee,
      f"(projetado={squat_projected:.1f} < real={expected_knee:.1f})")
check("na perna estendida a projecao ABRE o angulo", standing_projected > standing_true,
      f"(projetado={standing_projected:.1f} > real={standing_true:.1f})")

# A inclinação do tronco continua vindo da imagem, e com a câmera de perfil ela bate exatamente
# com a inclinação que se pôs no corpo.
lean = run_video(still(body(160.0, trunk_lean_deg=28.0), camera_deg=0.0))
check("inclinacao do tronco vem da imagem e bate de perfil",
      close(lean.frames[0].trunk_angle, 28.0, 0.2),
      f"(lido={lean.frames[0].trunk_angle:.2f})")


# --- Lado do corpo: escolhido uma vez, não quadro a quadro ---------------------

# Visibilidade oscilando perto do empate, com o lado 0 na frente na média. Os dois lados têm
# ângulos de joelho bem diferentes — se a escolha fosse por frame, o sinal alternaria entre
# eles, e o detector de repetição contaria essa alternância como movimento.
near, far = body(90.0), body(150.0)
flicker = []
for i in range(10):
    visibility = (0.92, 0.88) if i % 2 == 0 else (0.86, 0.90)
    image, world = make_pose(near, far=far, visibility=visibility)
    flicker.append(PoseResult(image, world))

extraction = run_video(flicker)
angles = {round(f.knee_angle) for f in extraction.frames}
check("lado escolhido uma vez para o video inteiro", angles == {90},
      f"(angulos lidos={sorted(angles)})")

# E quando o outro lado é claramente o mais visível, é ele que vale.
other = [PoseResult(*make_pose(near, far=far, visibility=(0.20, 0.95))) for _ in range(6)]
extraction = run_video(other)
check("com o outro lado mais visivel, o sinal vem dele",
      close(extraction.frames[0].knee_angle, 150.0, 1.0),
      f"(lido={extraction.frames[0].knee_angle:.1f})")


# --- Frames encobertos saem da conta, e a cobertura cai -----------------------

mixed = []
for i in range(10):
    visibility = (0.20, 0.15) if i < 3 else (0.95, 0.40)
    mixed.append(PoseResult(*make_pose(SQUAT, visibility=visibility)))

extraction = run_video(mixed)
check("frame encoberto nao vira sinal", len(extraction.frames) == 7,
      f"(frames={len(extraction.frames)})")
check("e a cobertura reflete isso", close(extraction.coverage, 0.7, 0.01),
      f"(cobertura={extraction.coverage:.2f})")


# --- O corte de visibilidade olha o elo mais fraco do que o exercício lê -------

CURL_JOINTS = ("shoulder", "elbow", "wrist", "hip")

# O caso que motivou a mudança, tirado de vídeo real: numa rosca enquadrada do peito para cima,
# ombro (0,997) e quadril (0,970) sustentavam a média enquanto o punho despencava. Só que o
# ângulo do cotovelo precisa dos TRÊS pontos — com o punho perdido, não há o que ler.
weak_wrist = []
for i in range(10):
    weak_wrist.append(PoseResult(*make_pose(
        SQUAT, visibility=(0.99, 0.10), weak={"wrist": 0.20} if i < 4 else None)))

extraction = run_video(weak_wrist, joints=CURL_JOINTS)
check("punho perdido derruba o frame, mesmo com ombro e quadril otimos",
      len(extraction.frames) == 6, f"(frames={len(extraction.frames)})")
mean_of_that_frame = (0.99 * 3 + 0.20) / 4
check("e a media daquele mesmo frame teria aprovado",
      mean_of_that_frame > analysis.MIN_SIDE_VISIBILITY,
      f"(media={mean_of_that_frame:.2f} vs corte={analysis.MIN_SIDE_VISIBILITY})")

# O outro lado da mesma moeda: exigir articulação que o exercício não lê. O tornozelo da rosca
# real estava FORA do enquadramento — inventado pelo modelo em 97% dos frames.
no_ankle = [PoseResult(*make_pose(SQUAT, visibility=(0.99, 0.10), weak={"ankle": 0.05}))
            for _ in range(6)]
check("tornozelo invisivel nao atrapalha uma rosca",
      len(run_video(no_ankle, joints=CURL_JOINTS).frames) == 6)
check("mas o mesmo video nao serve para agachamento",
      "encoberto" in (raises(lambda: run_video(no_ankle, joints=SQUAT_JOINTS)) or ""))


# --- O esqueleto desenhado sai do que o exercício lê ---------------------------

drawn, edges = analysis.skeleton(("shoulder", "wrist", "hip"))
check("articulacao intermediaria entra so para o osso fazer sentido",
      "elbow" in drawn and ("shoulder", "elbow") in edges and ("elbow", "wrist") in edges,
      f"(desenhadas={drawn})")
check("e nada da perna entra quando a perna nao e lida",
      "knee" not in drawn and "ankle" not in drawn, f"(desenhadas={drawn})")
check("o tronco liga ombro e quadril", ("shoulder", "hip") in edges, f"(ossos={edges})")


# --- Ângulo da câmera ---------------------------------------------------------

for camera_deg, ceiling, verdict in ((0.0, 0.10, "de perfil"),
                                     (40.0, 0.75, "torta mas aceitável"),
                                     (90.0, 1.10, "de frente")):
    extraction = run_video(still(SQUAT, camera_deg=camera_deg))
    frontality = extraction.frontality
    above = frontality > analysis.MAX_CAMERA_FRONTALITY
    check(f"camera a {camera_deg:.0f} graus: frontalidade {verdict}",
          frontality < ceiling and above == (camera_deg == 90.0),
          f"(frontalidade={frontality:.2f}, corte={analysis.MAX_CAMERA_FRONTALITY})")


# --- Os erros que o usuário consegue corrigir ---------------------------------

check("video ilegivel", (raises(lambda: run_video(still(SQUAT), opened=False)) or "")
      .startswith("Não foi possível ler o vídeo"))
check("video vazio", raises(lambda: run_video([])) == "Vídeo vazio ou corrompido.")
check("video longo demais",
      "o limite é 60s" in (raises(lambda: run_video(still(SQUAT), frame_count=800)) or ""),
      f"({raises(lambda: run_video(still(SQUAT), frame_count=800))})")
check("nenhuma pessoa detectada",
      "detectar uma pessoa" in (raises(
          lambda: run_video([PoseResult(None, None) for _ in range(6)])) or ""))
check("corpo encoberto o video inteiro",
      "encoberto" in (raises(lambda: run_video(
          [PoseResult(*make_pose(SQUAT, visibility=(0.1, 0.1))) for _ in range(6)])) or ""))


# --- Overlay: o writer nasce do frame, não dos metadados ----------------------

# O CAP_PROP_FRAME_WIDTH/HEIGHT pode reportar as dimensões SEM a rotação do celular, e o
# VideoWriter descarta em silêncio todo frame de tamanho diferente. Daí o writer sair do
# primeiro frame lido — este teste prende isso.
overlay_path = str(Path(analysis.tempfile.gettempdir()) / "myotrack-test-overlay.mp4")
extraction = run_video(still(SQUAT, frames=5), overlay=overlay_path)
check("writer criado com as dimensoes do frame", DRIVER.writer.size == (WIDTH, HEIGHT),
      f"(size={DRIVER.writer.size})")
check("todos os frames amostrados vao para o overlay", DRIVER.writer.written == 5,
      f"(escritos={DRIVER.writer.written})")
check("captura liberada", DRIVER.released)

# O agachamento lê ombro, quadril, joelho e tornozelo: quatro pontos e três ossos por frame.
check("desenha so as articulacoes que o agachamento le",
      len(DRIVER.circles) == 4 * 5 and len(DRIVER.lines) == 3 * 5,
      f"(pontos={len(DRIVER.circles)}, ossos={len(DRIVER.lines)})")

# E do LADO analisado. Desenhar os dois era metade do emaranhado: dois esqueletos sobrepostos,
# um deles nunca lido. As duas pernas ficam em ângulos bem diferentes para a asserção ter dente
# — a câmera de perfil projeta os dois lados no MESMO x, então corpos iguais não provariam nada.
far_body = body(150.0)
run_video(still(SQUAT, far=far_body, frames=5), overlay=overlay_path)
image, _ = make_pose(SQUAT, far=far_body)
pixel = lambda name, side: (int(image[INDEX[name][side]].x * WIDTH),
                            int(image[INDEX[name][side]].y * HEIGHT))
near_side = {pixel(name, 0) for name in SQUAT_JOINTS}
far_side = {pixel(name, 1) for name in SQUAT_JOINTS}
drawn_points = {center for center, _ in DRIVER.circles}
check("e apenas do lado que a analise escolheu",
      drawn_points == near_side and near_side != far_side,
      f"(desenhados={sorted(drawn_points)}, outro lado={sorted(far_side)})")

# Frame que o modelo viu mas a análise descartou sai em cinza, e não some nem se disfarça de
# frame bom. Sem essa distinção, um frame ruim desenhado com a confiança de um bom faz a
# análise inteira parecer chute — que é como ela parecia.
half_bad = [PoseResult(*make_pose(SQUAT, visibility=(0.95, 0.10) if i < 3 else (0.20, 0.10)))
            for i in range(6)]
extraction = run_video(half_bad, overlay=overlay_path)
colors = {color for _, color in DRIVER.circles}
check("frame descartado aparece em cinza, e o aproveitado em verde",
      colors == {analysis._COUNTED_COLOR, analysis._DISCARDED_COLOR}, f"(cores={colors})")
check("e nenhum frame amostrado some do overlay", DRIVER.writer.written == 6,
      f"(escritos={DRIVER.writer.written})")


# --- Osso que muda de tamanho é erro do modelo, e vira métrica ----------------

check("corpo parado tem segmentos constantes",
      run_video(still(SQUAT, frames=6)).segment_cv < 0.001)

# A canela encolhe e estica a cada frame. Nenhum gabarito humano precisou existir para dizer
# que isso é erro: o corpo simplesmente não faz isso.
wobble = []
for i in range(8):
    joints = dict(SQUAT)
    joints["ankle"] = (SQUAT["ankle"][0], SQUAT["ankle"][1] + 0.10 * (i % 2))
    wobble.append(PoseResult(*make_pose(joints)))
check("canela que muda de tamanho aparece no segment_cv",
      run_video(wobble).segment_cv > 0.05, f"(cv={run_video(wobble).segment_cv})")


# --- Ponta a ponta: vídeo sintético até o resultado da análise ----------------

def squat_video(reps, frames_per_rep=36, deep=85.0, top=172.0, camera_deg=0.0):
    poses = []
    for i in range(reps * frames_per_rep):
        phase = math.sin(math.pi * ((i % frames_per_rep) / frames_per_rep))
        image, world = make_pose(body(top - (top - deep) * phase), camera_deg=camera_deg)
        poses.append(PoseResult(image, world))
    return poses


DRIVER = Driver(squat_video(4))
result = evaluate("fake.mp4", "squat")
check("ponta a ponta: 4 repeticoes contadas", result["rep_count"] == 4,
      f"(reps={result['rep_count']})")
check("ponta a ponta: avaliavel", result["not_evaluable_reason"] is None,
      f"({result['not_evaluable_reason']})")
check("ponta a ponta: profundidade de 85 graus aprovada",
      "insufficient_depth" in [p["code"] for p in result["correct_points"]],
      f"(issues={[i['code'] for i in result['issues']]})")
check("ponta a ponta: a instrumentacao acompanha",
      any(c["code"] == "insufficient_depth" and c["slack"] is not None
          for c in result["metrics"]["checks"]))

# O custo do filtro de mediana, medido em vez de suposto.
#
# O agachamento sobe até 172°, bem acima do limite de 165, e mesmo assim `incomplete_lockout`
# reprova. O topo da senoide existe em UM quadro; a mediana de três o troca pelo vizinho, que
# está 7° abaixo, e sobra folga negativa. É o preço de rejeitar quadro estragado, e ele só
# aparece quando o extremo é instantâneo.
#
# Repetição de verdade tem uma parada no lockout, então isto deve doer menos na vida real que
# aqui — mas "deve" é justamente o que o corpus existe para confirmar. A folga abaixo é o
# número a comparar com a do primeiro vídeo real; se lá também for pequena e negativa, o
# problema é o filtro, e não a execução de quem gravou.
lockout = next(c for c in result["metrics"]["checks"] if c["code"] == "incomplete_lockout")
check("ponta a ponta: o lockout reprova por causa do filtro, nao da execucao",
      not lockout["passed"] and -3.0 < lockout["slack"] < 0.0,
      f"(folga={lockout['slack']}, leitura={lockout['readings'][0]['value']}, "
      f"topo real=172)")

DRIVER = Driver(squat_video(4, camera_deg=90.0))
result = evaluate("fake.mp4", "squat")
check("ponta a ponta: mesma execucao gravada de frente e recusada",
      "de frente" in (result["not_evaluable_reason"] or ""),
      f"({result['not_evaluable_reason']})")
check("e sem nota, em vez de nota errada", result["score"] is None)

print()
print("TODOS OS TESTES PASSARAM" if ok else "HA FALHAS")
sys.exit(0 if ok else 1)
