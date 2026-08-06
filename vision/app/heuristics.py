"""Heurísticas de execução por exercício (câmera lateral, corpo inteiro).

Motor declarativo: cada exercício é uma ExerciseSpec com um sinal principal
(que define as repetições) e uma lista de checagens por repetição. Checagem
que passa em todas as reps vira "ponto correto"; a que falha vira "ponto de
atenção" com os timestamps das reps em que falhou — assim toda análise
avaliável devolve os dois lados da execução.

Filosofia: score conservador — na dúvida (pouca pose detectada, nenhuma
repetição clara), devolver "não avaliável" em vez de feedback errado.
"""

from collections.abc import Callable
from dataclasses import dataclass, field

from .analysis import FrameSignals

# Faixa mínima de variação do sinal para considerarmos que houve movimento.
MIN_SIGNAL_RANGE_DEG = 25.0
MIN_WRIST_TRAVEL = 0.10   # coordenadas normalizadas (fração da altura da imagem)
MIN_SHRUG_TRAVEL = 0.025  # encolhimento tem amplitude pequena por natureza


@dataclass
class Issue:
    code: str
    message: str
    timestamps_sec: list[float] = field(default_factory=list)


@dataclass
class CorrectPoint:
    code: str
    message: str


@dataclass
class HeuristicResult:
    rep_count: int
    issues: list[Issue]
    correct_points: list[CorrectPoint]
    metrics: dict
    not_evaluable_reason: str | None = None


@dataclass
class Rep:
    """Uma repetição detectada.

    window: frames em torno do extremo do movimento (fundo do agachamento,
    topo do press...) — para checagens de posição no extremo.
    segment: frames do extremo desta rep até o extremo da próxima — cobre a
    volta do movimento (lockout do terra, extensão do braço entre roscas...).
    """
    t: float
    window: list[FrameSignals]
    segment: list[FrameSignals]


@dataclass
class Check:
    """Uma checagem por repetição, com as duas leituras do resultado."""
    code: str
    fail_message: str
    ok_message: str
    passes: Callable[[Rep], bool]

    # Deixa a última repetição de fora.
    #
    # O `segment` da última vai do fundo dela até o FIM DO VÍDEO — quem terminou a série e
    # parou, largou o peso ou desligou a câmera nunca "volta", e toda checagem que lê o que
    # vem depois do fundo reprova essa repetição sempre. É falso positivo sistemático, e o
    # pior tipo: aparece só na última, que é onde o usuário menos duvida do app.
    #
    # Só vale a partir de duas repetições — com uma, ignorá-la seria não checar nada.
    skip_last: bool = False


@dataclass
class SeriesCheck:
    """Uma checagem sobre a série inteira: o que só se enxerga comparando repetições.

    Devolve as repetições que destoam, e não um booleano, porque é delas que saem os
    timestamps — sem eles a ocorrência não teria instante para o app apontar, e a nota não
    seria penalizada (`compute_score` conta ocorrências por timestamp).
    """
    code: str
    fail_message: str
    ok_message: str
    offenders: Callable[[list[Rep]], list[Rep]]


@dataclass
class ExerciseSpec:
    label: str                                   # em minúsculas, para mensagens
    signal: Callable[[FrameSignals], float]      # sinal que define a repetição
    signal_name: str                             # nome do sinal nas métricas
    extremum: str                                # "bottom" | "top" do sinal
    min_range: float                             # variação mínima = houve movimento
    checks: list[Check]
    series_checks: list[SeriesCheck] = field(default_factory=list)


def _smooth(values: list[float], window: int = 5) -> list[float]:
    half = window // 2
    return [
        sum(values[max(0, i - half):i + half + 1]) / len(values[max(0, i - half):i + half + 1])
        for i in range(len(values))
    ]


def _find_bottoms(values: list[float], times: list[float], min_swing: float) -> list[float]:
    """Instantes dos fundos do sinal — uma repetição por fundo.

    Alterna entre procurar fundo e procurar topo, e só confirma uma virada quando o sinal já
    andou `min_swing` **em unidades do próprio sinal** (graus, ou fração da altura da imagem)
    no sentido contrário. É o mesmo princípio da histerese, aplicado ao trecho e não ao vídeo.

    **A versão anterior normalizava o sinal pela faixa do vídeo inteiro** e disparava em 35% e
    65% dela. Isso fazia a repetição ser medida contra a *melhor* repetição da série, e o
    efeito era perverso:

    - Uma repetição bem mais curta que as outras não cruzava os 35% e **não virava repetição
      nenhuma** — as piores eram exatamente as que sumiam, e o sintoma chegava ao usuário como
      contagem baixa em vez de "profundidade caiu".
    - Repetições sem extensão completa entre elas nunca voltavam aos 65%, e a máquina de
      estados fundia a série toda num ciclo só. Era o que contava uma rosca de 23,5 s como
      uma repetição.
    - E uma única repetição muito funda esticava a faixa, levantando a régua para todas as
      outras.

    Em unidades absolutas nada disso acontece: cada oscilação vale por si.
    """
    if len(values) < 2 or min_swing <= 0:
        return []

    bottoms: list[float] = []
    # Começa procurando fundo, com o primeiro ponto como candidato: um vídeo que começa no
    # fundo do movimento tem essa primeira repetição contada, e um que começa em pé não gera
    # fundo falso — de pé, o sinal só sobe depois de descer.
    seeking_bottom = True
    best_t, best_v = times[0], values[0]

    for t, v in zip(times, values):
        if seeking_bottom:
            if v < best_v:
                best_t, best_v = t, v
            elif v - best_v >= min_swing:
                bottoms.append(best_t)
                seeking_bottom, best_t, best_v = False, t, v
        else:
            if v > best_v:
                best_t, best_v = t, v
            elif best_v - v >= min_swing:
                seeking_bottom, best_t, best_v = True, t, v

    return bottoms


def _window(frames: list[FrameSignals], center: float, radius: float = 0.5) -> list[FrameSignals]:
    return [f for f in frames if abs(f.t - center) <= radius]


def _segment(frames: list[FrameSignals], start: float, end: float) -> list[FrameSignals]:
    return [f for f in frames if start <= f.t < end]


def analyze(spec: ExerciseSpec, frames: list[FrameSignals]) -> HeuristicResult:
    times = [f.t for f in frames]
    series = _smooth([spec.signal(f) for f in frames])
    if max(series) - min(series) < spec.min_range:
        return HeuristicResult(0, [], [], {}, f"Nenhuma repetição de {spec.label} detectada no vídeo.")

    # Extremos no topo (press, elevação...) = "fundos" do sinal invertido. A inversão preserva
    # a magnitude, então o `min_swing` vale igual nos dois casos.
    oriented = series if spec.extremum == "bottom" else [-v for v in series]
    # O mesmo número que define "houve movimento no vídeo" define "houve movimento nesta
    # repetição". Ele já é por exercício — 25° para ângulo, 0,10 de altura para punho, 0,025
    # para encolhimento —, que é exatamente a escala que o detector precisa conhecer.
    extremes = _find_bottoms(oriented, times, spec.min_range)
    if not extremes:
        return HeuristicResult(0, [], [], {}, "Nenhuma repetição completa detectada.")

    boundaries = extremes[1:] + [times[-1] + 1]
    reps = [
        Rep(t=t, window=_window(frames, t), segment=_segment(frames, t, next_t))
        for t, next_t in zip(extremes, boundaries)
    ]
    reps = [r for r in reps if r.window]

    issues: list[Issue] = []
    correct_points: list[CorrectPoint] = []
    for check in spec.checks:
        checked = reps[:-1] if check.skip_last and len(reps) > 1 else reps
        failed_at = [round(r.t, 1) for r in checked if not check.passes(r)]
        if failed_at:
            issues.append(Issue(check.code, check.fail_message, failed_at))
        else:
            correct_points.append(CorrectPoint(check.code, check.ok_message))

    # `series_check`, e não `series`: esta função já tem um `series` — o sinal suavizado —, e
    # o laço o sobrescrevia. O erro só aparecia no fim, ao montar as métricas.
    for series_check in spec.series_checks:
        offenders = series_check.offenders(reps)
        if offenders:
            issues.append(Issue(
                series_check.code,
                series_check.fail_message,
                [round(r.t, 1) for r in offenders]))
        else:
            correct_points.append(
                CorrectPoint(series_check.code, series_check.ok_message))

    return HeuristicResult(
        rep_count=len(extremes),
        issues=issues,
        correct_points=correct_points,
        metrics={
            f"min_{spec.signal_name}": round(min(series), 2),
            f"max_{spec.signal_name}": round(max(series), 2),
            "max_trunk_lean_deg": round(max(f.trunk_angle for f in frames), 1),
        },
    )


# ---------------------------------------------------------------------------
# Sinais e condições reutilizados pelas specs.

def _knee(f: FrameSignals) -> float:
    return f.knee_angle


def _hip(f: FrameSignals) -> float:
    return f.hip_angle


def _elbow(f: FrameSignals) -> float:
    return f.elbow_angle


def _wrist_height(f: FrameSignals) -> float:
    # Altura do punho acima do ombro (y de imagem cresce para baixo).
    return f.shoulder_y - f.wrist_y


def _shoulder_elevation(f: FrameSignals) -> float:
    # Distância ombro-quadril: relativa ao corpo, cancela balanço da câmera/tronco.
    return f.hip_y - f.shoulder_y


def _body_elevation(f: FrameSignals) -> float:
    # Na elevação de calcanhar o corpo inteiro sobe — o quadril acompanha
    # (sinais relativos entre articulações se cancelam; aqui o absoluto é o certo).
    return -f.hip_y


def _trunk_stable(rep: Rep, max_range: float) -> bool:
    angles = [f.trunk_angle for f in rep.segment or rep.window]
    return max(angles) - min(angles) <= max_range


def _squat_depth(rep: Rep) -> bool:
    # Profundidade: joelho fechando o suficiente OU quadril na linha do joelho.
    lowest = min(rep.window, key=lambda f: f.knee_angle)
    return lowest.knee_angle <= 100 or lowest.hip_y >= lowest.knee_y - 0.02


def _shallow_reps(reps: list[Rep], tolerance: float = 20.0) -> list[Rep]:
    """As repetições que ficaram bem mais curtas que a mais funda da própria série.

    **A referência é a melhor repetição, não a média.** O que se quer dizer é "você desce até
    aqui, e nestas você não desceu" — comparar com a média diluiria justamente a repetição
    encurtada dentro do número que ela mesma puxou para baixo.

    Abaixo de três repetições não há série para comparar: com duas, chamar uma de destoante é
    ruído, porque não há como saber qual das duas é a típica.
    """
    if len(reps) < 3:
        return []
    depths = [min(f.knee_angle for f in rep.window) for rep in reps]
    deepest = min(depths)
    return [rep for rep, depth in zip(reps, depths) if depth - deepest > tolerance]


# ---------------------------------------------------------------------------
# Catálogo de exercícios suportados.

SPECS: dict[str, ExerciseSpec] = {
    "squat": ExerciseSpec(
        label="agachamento", signal=_knee, signal_name="knee_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("insufficient_depth",
                  "Profundidade insuficiente: desça até o quadril passar da linha do joelho.",
                  "Profundidade adequada — o quadril chegou à linha do joelho.",
                  _squat_depth),
            # 55° era quase um bom-dia: nessa inclinação o quadril já assumiu o movimento e a
            # barra saiu da linha do pé. 45 reprova o que precisa ser reprovado e ainda deixa
            # margem para quem tem fêmur longo, que agacha inclinado por anatomia e não por
            # erro — o agachamento medido nesta calibração fica em 30–34°.
            Check("excessive_trunk_lean",
                  "Inclinação excessiva do tronco na descida — mantenha o peito mais erguido.",
                  "Tronco firme na descida, sem inclinar demais.",
                  lambda rep: max(f.trunk_angle for f in rep.window) <= 45),
            # Subir só até 165° já é joelho praticamente estendido; abaixo disso a pessoa
            # emendou a próxima repetição agachada, que é o erro que rouba a parte final do
            # movimento e cansa o quadríceps antes da hora.
            Check("incomplete_lockout",
                  "Você emenda a próxima repetição sem terminar de subir — estenda o joelho "
                  "por completo entre elas.",
                  "Extensão completa do joelho entre as repetições.",
                  lambda rep: max(
                      f.knee_angle for f in rep.segment or rep.window) >= 165,
                  skip_last=True),
        ],
        series_checks=[
            SeriesCheck("inconsistent_depth",
                        "A profundidade caiu no meio da série — as repetições marcadas ficaram "
                        "bem mais curtas que a sua melhor.",
                        "Profundidade constante do começo ao fim da série.",
                        _shallow_reps),
        ]),
    "lunge": ExerciseSpec(
        label="afundo", signal=_knee, signal_name="knee_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("insufficient_depth",
                  "Desça mais — o joelho da frente deve dobrar até cerca de 90°.",
                  "Boa amplitude na descida do afundo.",
                  lambda rep: min(f.knee_angle for f in rep.window) <= 100),
            Check("excessive_trunk_lean",
                  "Tronco inclinando demais para a frente — mantenha-o ereto.",
                  "Tronco ereto durante o movimento.",
                  lambda rep: max(f.trunk_angle for f in rep.window) <= 30),
        ]),
    "deadlift": ExerciseSpec(
        label="levantamento terra", signal=_hip, signal_name="hip_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_lockout",
                  "Extensão de quadril incompleta no topo — finalize o movimento ereto.",
                  "Extensão completa de quadril no topo (lockout).",
                  lambda rep: max(f.hip_angle for f in rep.segment or rep.window) >= 160),
            Check("stiff_legs_at_start",
                  "Pernas quase esticadas na saída do chão — dobre mais os joelhos e use as pernas.",
                  "Boa flexão de pernas na saída do chão.",
                  lambda rep: min(f.knee_angle for f in rep.window) <= 145),
        ]),
    "romanian_deadlift": ExerciseSpec(
        label="terra romeno", signal=_hip, signal_name="hip_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_lockout",
                  "Extensão de quadril incompleta no topo — finalize o movimento ereto.",
                  "Extensão completa do quadril no topo.",
                  lambda rep: max(f.hip_angle for f in rep.segment or rep.window) >= 160),
            Check("excessive_knee_bend",
                  "Joelhos dobrando demais — no terra romeno, mantenha-os quase estendidos.",
                  "Joelhos firmes, com dobra mínima — bom padrão de dobradiça de quadril.",
                  lambda rep: min(f.knee_angle for f in rep.window) >= 130),
        ]),
    "hip_thrust": ExerciseSpec(
        label="elevação de quadril", signal=_hip, signal_name="hip_angle_deg",
        extremum="top", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_extension",
                  "Suba mais o quadril — estenda por completo no topo do movimento.",
                  "Extensão completa do quadril no topo.",
                  lambda rep: max(f.hip_angle for f in rep.window) >= 160),
            Check("short_range",
                  "Amplitude curta — desça mais o quadril entre as repetições.",
                  "Boa amplitude de movimento entre as repetições.",
                  lambda rep: min(f.hip_angle for f in rep.segment or rep.window) <= 120),
        ]),
    "back_extension": ExerciseSpec(
        # Banco romano: o ângulo do quadril é relativo às articulações,
        # então funciona com o corpo inclinado a 45°.
        label="extensão lombar", signal=_hip, signal_name="hip_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_extension",
                  "Suba até alinhar o tronco com as pernas — sem encurtar a subida.",
                  "Extensão completa no topo, tronco alinhado com as pernas.",
                  lambda rep: max(f.hip_angle for f in rep.segment or rep.window) >= 160),
            Check("short_range",
                  "Amplitude curta — desça o tronco com controle até perto da vertical.",
                  "Boa amplitude na descida.",
                  lambda rep: min(f.hip_angle for f in rep.window) <= 130),
        ]),
    "bench_press": ExerciseSpec(
        label="supino", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("short_range",
                  "Amplitude curta na descida — leve a barra até perto do peito.",
                  "Boa amplitude na descida da barra.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 100),
            Check("incomplete_lockout",
                  "Cotovelos não estenderam por completo no topo do movimento.",
                  "Extensão completa dos cotovelos no topo.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 160),
        ]),
    "push_up": ExerciseSpec(
        label="flexão de braço", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("insufficient_depth",
                  "Desça mais — dobre os cotovelos até o peito se aproximar do chão.",
                  "Boa profundidade na descida.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 100),
            Check("hip_sag",
                  "Corpo desalinhado — quadril caindo ou empinando; contraia o abdômen e o glúteo.",
                  "Corpo alinhado durante toda a flexão, como uma prancha.",
                  lambda rep: min(f.hip_angle for f in rep.segment or rep.window) >= 150),
        ]),
    "dips": ExerciseSpec(
        label="mergulho em paralelas", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("insufficient_depth",
                  "Desça mais — dobre os cotovelos até cerca de 90°.",
                  "Boa profundidade na descida.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 100),
            Check("incomplete_lockout",
                  "Estenda os cotovelos por completo no topo do movimento.",
                  "Extensão completa dos cotovelos no topo.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 160),
        ]),
    "triceps_pushdown": ExerciseSpec(
        # O extremo da rep é a EXTENSÃO do cotovelo (empurrão até embaixo).
        label="tríceps na polia", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="top", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_extension",
                  "Estenda o cotovelo por completo no fim do empurrão.",
                  "Extensão completa do cotovelo no fim do empurrão.",
                  lambda rep: max(f.elbow_angle for f in rep.window) >= 160),
            Check("short_range",
                  "Amplitude curta — deixe o antebraço subir controlado até fechar o cotovelo.",
                  "Boa amplitude no retorno do movimento.",
                  lambda rep: min(f.elbow_angle for f in rep.segment or rep.window) <= 100),
            Check("torso_swing",
                  "Tronco debruçando sobre a polia para empurrar — mantenha o corpo parado.",
                  "Tronco estável — força só do tríceps.",
                  lambda rep: _trunk_stable(rep, 15)),
        ]),
    "overhead_press": ExerciseSpec(
        label="desenvolvimento", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        checks=[
            Check("incomplete_lockout",
                  "Cotovelos não estenderam por completo no topo do movimento.",
                  "Cotovelos estendidos por completo no topo.",
                  lambda rep: max(f.elbow_angle for f in rep.window) >= 160),
            Check("excessive_back_lean",
                  "Tronco inclinando demais para trás — contraia o abdômen e o glúteo.",
                  "Tronco estável, sem inclinar para trás.",
                  lambda rep: max(f.trunk_angle for f in rep.window) <= 25),
        ]),
    "lat_pulldown": ExerciseSpec(
        label="puxada alta", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — traga a barra até a altura do queixo ou do peito.",
                  "Puxada completa, com a barra chegando à altura do peito.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 90),
            Check("incomplete_extension",
                  "Estenda os braços por completo no retorno da barra.",
                  "Extensão completa dos braços no retorno.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 150),
            Check("torso_swing",
                  "Tronco inclinando para trás para puxar — estabilize e puxe com as costas.",
                  "Tronco estável durante a puxada.",
                  lambda rep: _trunk_stable(rep, 20)),
        ]),
    "seated_cable_row": ExerciseSpec(
        label="remada baixa", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — leve o punho até o tronco.",
                  "Puxada completa, com o punho chegando ao tronco.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 90),
            Check("incomplete_extension",
                  "Estenda os braços por completo no retorno.",
                  "Extensão completa dos braços no retorno.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 150),
            Check("torso_swing",
                  "Tronco balançando para frente e para trás — puxe com as costas, não com o embalo.",
                  "Tronco estável, sem embalo.",
                  lambda rep: _trunk_stable(rep, 20)),
        ]),
    "dumbbell_row": ExerciseSpec(
        label="remada serrote", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — suba o halter até a linha do tronco.",
                  "Puxada completa, com o halter chegando ao tronco.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 90),
            Check("incomplete_extension",
                  "Estenda o braço por completo na descida do halter.",
                  "Extensão completa do braço na descida.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 150),
            Check("torso_swing",
                  "Tronco girando/balançando para ajudar — mantenha a posição apoiada e estável.",
                  "Tronco firme na posição apoiada.",
                  lambda rep: _trunk_stable(rep, 15)),
        ]),
    "barbell_row": ExerciseSpec(
        label="remada curvada", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — leve o cotovelo mais para trás, até a barra tocar o tronco.",
                  "Puxada completa, com a barra chegando ao tronco.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 90),
            Check("torso_swing",
                  "Tronco balançando para ajudar a puxada — estabilize a posição curvada.",
                  "Tronco estável na posição curvada durante toda a série.",
                  lambda rep: _trunk_stable(rep, 20)),
        ]),
    "biceps_curl": ExerciseSpec(
        label="rosca bíceps", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_curl",
                  "Flexão incompleta — suba o peso até o fim do movimento.",
                  "Flexão completa no topo do movimento.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 70),
            Check("incomplete_extension",
                  "Estenda o braço por completo entre as repetições.",
                  "Extensão completa do braço entre as repetições.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 150),
            Check("torso_swing",
                  "Balanço de tronco (roubo) — mantenha o corpo parado e isole o bíceps.",
                  "Sem balanço de tronco — movimento isolado no bíceps.",
                  lambda rep: _trunk_stable(rep, 15)),
        ]),
    "hammer_curl": ExerciseSpec(
        label="rosca martelo", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_curl",
                  "Flexão incompleta — suba o peso até o fim do movimento.",
                  "Flexão completa no topo do movimento.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 70),
            Check("incomplete_extension",
                  "Estenda o braço por completo entre as repetições.",
                  "Extensão completa do braço entre as repetições.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 150),
            Check("torso_swing",
                  "Balanço de tronco (roubo) — mantenha o corpo parado e isole o braço.",
                  "Sem balanço de tronco — movimento isolado no braço.",
                  lambda rep: _trunk_stable(rep, 15)),
        ]),
    "preacher_curl": ExerciseSpec(
        # Braço apoiado no banco: sem checagem de balanço de tronco.
        label="rosca scott", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_curl",
                  "Flexão incompleta — suba o peso até o fim do movimento.",
                  "Flexão completa no topo do movimento.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 70),
            Check("incomplete_extension",
                  "Estenda o braço por completo na descida — sem repetições pela metade.",
                  "Extensão completa do braço na descida.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 150),
        ]),
    "pull_up": ExerciseSpec(
        label="barra fixa", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        checks=[
            Check("incomplete_pull",
                  "Subida incompleta — puxe até o queixo passar da linha da barra.",
                  "Subida completa, com boa flexão dos cotovelos.",
                  lambda rep: min(f.elbow_angle for f in rep.window) <= 90),
            Check("incomplete_extension",
                  "Estenda os braços por completo na descida (dead hang).",
                  "Extensão completa dos braços na descida.",
                  lambda rep: max(f.elbow_angle for f in rep.segment or rep.window) >= 160),
        ]),
    "calf_raise": ExerciseSpec(
        label="panturrilha em pé", signal=_body_elevation, signal_name="body_elevation",
        extremum="top", min_range=MIN_SHRUG_TRAVEL,
        checks=[
            Check("knee_bend",
                  "Joelhos dobrando durante a subida — mantenha-os estendidos para isolar a panturrilha.",
                  "Joelhos estendidos — o trabalho ficou na panturrilha.",
                  lambda rep: min(f.knee_angle for f in rep.segment or rep.window) >= 160),
            Check("torso_swing",
                  "Corpo inclinando para ganhar impulso — suba na vertical, com controle.",
                  "Subida vertical e controlada, sem impulso.",
                  lambda rep: _trunk_stable(rep, 10)),
        ]),
    "shrug": ExerciseSpec(
        label="encolhimento", signal=_shoulder_elevation, signal_name="shoulder_elevation",
        extremum="top", min_range=MIN_SHRUG_TRAVEL,
        checks=[
            Check("elbow_bend",
                  "Cotovelos dobrando para ajudar — mantenha os braços estendidos e suba apenas os ombros.",
                  "Braços estendidos — o movimento ficou por conta do trapézio.",
                  lambda rep: min(f.elbow_angle for f in rep.segment or rep.window) >= 150),
            Check("torso_swing",
                  "Impulso com o corpo — mantenha o tronco parado e encolha os ombros com controle.",
                  "Tronco estável durante o encolhimento.",
                  lambda rep: _trunk_stable(rep, 10)),
        ]),
    "front_raise": ExerciseSpec(
        # Elevação no plano sagital — a mais visível de todas na câmera lateral.
        label="elevação frontal", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        checks=[
            Check("short_range",
                  "Suba os braços até a linha dos ombros.",
                  "Braços subindo até a linha dos ombros.",
                  lambda rep: min(f.wrist_y - f.shoulder_y for f in rep.window) <= 0.03),
            Check("torso_swing",
                  "Balanço de tronco para impulsionar o peso — mantenha o corpo parado.",
                  "Sem balanço de tronco — movimento controlado.",
                  lambda rep: _trunk_stable(rep, 12)),
        ]),
    "upright_row": ExerciseSpec(
        label="remada alta", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        checks=[
            Check("short_range",
                  "Puxada curta — suba a barra até a linha do peitoral superior, cotovelos na altura dos ombros.",
                  "Barra subindo até a linha do peitoral superior.",
                  lambda rep: min(f.wrist_y - f.shoulder_y for f in rep.window) <= 0.10),
            Check("torso_swing",
                  "Balanço de tronco para impulsionar a barra — mantenha o corpo parado.",
                  "Sem balanço de tronco — puxada controlada.",
                  lambda rep: _trunk_stable(rep, 15)),
        ]),
    "lateral_raise": ExerciseSpec(
        label="elevação lateral", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        checks=[
            Check("short_range",
                  "Suba os braços até a linha dos ombros.",
                  "Braços subindo até a linha dos ombros.",
                  lambda rep: min(f.wrist_y - f.shoulder_y for f in rep.window) <= 0.03),
            Check("torso_swing",
                  "Balanço de tronco para impulsionar o peso — mantenha o corpo parado.",
                  "Sem balanço de tronco — movimento controlado.",
                  lambda rep: _trunk_stable(rep, 12)),
        ]),
}

# Interface consumida pelo main.py: slug -> callable(frames) -> HeuristicResult.
HEURISTICS = {slug: (lambda frames, s=spec: analyze(s, frames)) for slug, spec in SPECS.items()}


def compute_score(result: HeuristicResult) -> int | None:
    """100 − 12 por ocorrência de erro (máx. 36 por tipo). Conservador e simples."""
    if result.not_evaluable_reason:
        return None
    penalty = sum(min(36, 12 * len(issue.timestamps_sec)) for issue in result.issues)
    return max(0, 100 - penalty)
