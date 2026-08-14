"""Heurísticas de execução por exercício (câmera lateral, corpo inteiro).

Motor declarativo: cada exercício é uma ExerciseSpec com um sinal principal
(que define as repetições) e uma lista de checagens por repetição. Checagem
que passa em todas as reps vira "ponto correto"; a que falha vira "ponto de
atenção" com os timestamps das reps em que falhou — assim toda análise
avaliável devolve os dois lados da execução.

Filosofia: score conservador — na dúvida (pouca pose detectada, nenhuma
repetição clara), devolver "não avaliável" em vez de feedback errado.
"""

import statistics
from collections.abc import Callable
from dataclasses import dataclass, field

from .analysis import FrameSignals

# Faixa mínima de variação do sinal para considerarmos que houve movimento.
MIN_SIGNAL_RANGE_DEG = 25.0
MIN_WRIST_TRAVEL = 0.10   # coordenadas normalizadas (fração da altura da imagem)
MIN_SHRUG_TRAVEL = 0.025  # encolhimento tem amplitude pequena por natureza

# Suavização do sinal que define as repetições, em SEGUNDOS.
#
# Era um número de amostras (5), e amostra não é tempo: o passo de amostragem é
# `round(fps / 12)`, então um vídeo de 30 fps chega aqui a 10 fps e um de 24 fps a 12 fps.
# A mesma janela de 5 amostras valia 0,50 s num e 0,42 s no outro — o mesmo movimento,
# gravado em celulares diferentes, era suavizado com força diferente.
SMOOTHING_SEC = 0.4

# Meia-largura da janela do extremo, como fração do período da repetição.
WINDOW_RADIUS_FRACTION = 0.25
MIN_WINDOW_RADIUS_SEC = 0.25
MAX_WINDOW_RADIUS_SEC = 0.75
DEFAULT_WINDOW_RADIUS_SEC = 0.5  # com uma repetição só não há período para medir


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
class Threshold:
    """Uma leitura da repetição e o limite contra o qual ela é comparada.

    Existe para o número que DECIDE e o número que o relatório mostra serem o mesmo. Enquanto
    a checagem era um lambda que devolvia booleano, instrumentar significava recalcular a
    leitura por fora — duas fontes de verdade que só precisam divergir uma vez para o relatório
    mentir justamente onde alguém foi conferir.
    """
    measure: Callable[[Rep], float]
    limit: float
    at_most: bool          # True: passa com medida <= limite; False: passa com medida >= limite
    unit: str = "deg"
    label: str = ""        # só faz falta quando a checagem tem mais de uma leitura

    def slack(self, rep: Rep) -> float:
        """Quanto sobrou (positivo) ou faltou (negativo) para o limite nesta repetição.

        É o número que diz se um "ponto correto" foi folgado ou passou raspando — e, portanto,
        se o limite está no lugar ou só parece estar.
        """
        value = self.measure(rep)
        return self.limit - value if self.at_most else value - self.limit

    def passes(self, rep: Rep) -> bool:
        return self.slack(rep) >= 0

    def reading(self, reps: list[Rep]) -> dict:
        """A leitura da repetição que passou mais perto de reprovar, ou que mais reprovou."""
        comparison = "at_most" if self.at_most else "at_least"
        if not reps:
            return {"label": self.label, "value": None, "limit": self.limit,
                    "comparison": comparison, "unit": self.unit, "slack": None}

        worst = min(reps, key=self.slack)
        return {
            "label": self.label,
            "value": round(self.measure(worst), 3),
            "limit": self.limit,
            "comparison": comparison,
            "unit": self.unit,
            "slack": round(self.slack(worst), 3),
        }


def at_most(measure: Callable[[Rep], float], limit: float,
            unit: str = "deg", label: str = "") -> Threshold:
    return Threshold(measure, limit, True, unit, label)


def at_least(measure: Callable[[Rep], float], limit: float,
             unit: str = "deg", label: str = "") -> Threshold:
    return Threshold(measure, limit, False, unit, label)


@dataclass
class Check:
    """Uma checagem por repetição, com as duas leituras do resultado."""
    code: str
    fail_message: str
    ok_message: str

    # A repetição passa quando QUALQUER limite passa. Só a profundidade do agachamento tem mais
    # de um: o mesmo defeito tem duas leituras válidas ali, o ângulo do joelho e a linha
    # quadril-joelho, e exigir as duas reprovaria quem tem fêmur longo por anatomia.
    thresholds: list[Threshold]

    # Deixa a última repetição de fora QUANDO o vídeo acabou cedo demais.
    #
    # O `segment` da última vai do fundo dela até o FIM DO VÍDEO. Quem largou o peso e desligou
    # a câmera nunca "volta", e toda checagem que lê o que vem depois do fundo reprovaria essa
    # repetição sempre — falso positivo sistemático, e do pior tipo: aparece só na última, que
    # é onde o usuário menos duvida do app.
    #
    # Mas a condição é o vídeo ter acabado, e não a repetição ser a última. Ignorá-la sempre
    # custa caro na direção oposta: a última é onde a fadiga cobra, e é a mais provável de ter
    # o erro que o usuário precisa ver. Quem continuou gravando tem a volta registrada, e aí
    # ela é julgada como qualquer outra — quem decide é `_last_rep_truncated`.
    #
    # Só vale a partir de duas repetições — com uma, ignorá-la seria não checar nada.
    #
    # Vai nas checagens de RETORNO, que exigem que o movimento ALCANCE um extremo depois do
    # fundo — `_highest(...) >= x` e `_lowest(...) <= x`. Não vai nas que exigem MANTER algo ao
    # longo do trecho — `_lowest(...) >= x` e `_highest(...) <= x`, como o quadril alinhado da
    # flexão ou o tronco parado da rosca. Nessas, o vídeo acabar cedo só tira dados: tira a
    # chance de reprovar, nunca a inventa, e pular a última repetição custaria detecção de
    # graça.
    skip_last: bool = False

    def passes(self, rep: Rep) -> bool:
        return any(threshold.passes(rep) for threshold in self.thresholds)

    def slack(self, reps: list[Rep]) -> float | None:
        """A margem que DECIDIU a checagem, na unidade do limite.

        Por repetição, a melhor folga entre os limites — basta um passar. Da série, a pior
        delas, porque uma repetição ruim reprova a checagem inteira. Assim `slack >= 0` é
        exatamente `passed`, inclusive quando repetições diferentes passam por limites
        diferentes — o caso da profundidade do agachamento, em que a folga por limite,
        isolada, chega a parecer reprovação nos dois.
        """
        if not reps:
            return None
        return round(
            min(max(t.slack(rep) for t in self.thresholds) for rep in reps), 3)

    def report(self, reps: list[Rep], passed: bool) -> dict:
        return {
            "code": self.code,
            "passed": passed,
            "reps_checked": len(reps),
            "slack": self.slack(reps),
            "readings": [threshold.reading(reps) for threshold in self.thresholds],
        }


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
    # As articulações que ESTE exercício lê, entre as de `analysis.JOINTS`. Obrigatório, e sem
    # default de propósito: espec que não diz o que lê faria a extração exigir o corpo inteiro
    # de novo, que é o erro que este campo existe para não deixar voltar. É a união do que o
    # `signal` e cada `Check` tocam — ângulo de cotovelo precisa de ombro+cotovelo+punho,
    # inclinação de tronco precisa de ombro+quadril, e por aí.
    joints: tuple[str, ...]
    checks: list[Check]
    series_checks: list[SeriesCheck] = field(default_factory=list)


def _sample_window(times: list[float], seconds: float) -> int:
    """Quantas amostras cobrem `seconds` neste vídeo. Ímpar, para a janela ficar centrada."""
    if len(times) < 2:
        return 1
    step = statistics.median(b - a for a, b in zip(times, times[1:]))
    if step <= 0:
        return 1
    window = max(1, round(seconds / step))
    return window + 1 if window % 2 == 0 else window


def _smooth(values: list[float], times: list[float]) -> list[float]:
    half = _sample_window(times, SMOOTHING_SEC) // 2
    return [
        sum(values[max(0, i - half):i + half + 1]) / len(values[max(0, i - half):i + half + 1])
        for i in range(len(values))
    ]


def _median_filter(values: list[float], window: int = 3) -> list[float]:
    """Mediana móvel de três amostras.

    Nas duas pontas do trecho a janela encolhe, e com duas amostras a mediana é a média delas:
    um frame estragado exatamente na virada do movimento é atenuado pela metade, em vez de
    sumir. Fica assim de propósito. Deslizar a janela para dentro, em vez de encolher, apaga
    esse frame e cobra caro em troca: o trecho da ÚLTIMA repetição termina junto com o vídeo,
    o extremo dela costuma cair no último quadro, e deslizar a janela puxa esse extremo para o
    meio do movimento — "extensão incompleta" passaria a aparecer em quem terminou a série
    normalmente, que é o falso positivo mais caro que existe aqui.
    """
    half = window // 2
    return [
        statistics.median(values[max(0, i - half):i + half + 1])
        for i in range(len(values))
    ]


def _lowest(frames: list[FrameSignals], signal: Callable[[FrameSignals], float]) -> float:
    """O menor valor do sinal no trecho, imune a um frame solto.

    `min` cru é um amplificador de outlier, e as checagens leem justamente o extremo: bastava
    um frame em que o MediaPipe errou o tornozelo para uma repetição rasa passar por funda.
    A mediana móvel de três amostras apaga o pico de UM frame e preserva o extremo de verdade,
    que dura mais que isso — o fundo de um agachamento não passa em 80 ms.

    Percentil (p10/p90) foi considerado e é pior aqui: em trecho longo, como o `segment`, o
    extremo é um evento breve e legítimo, e o percentil o jogaria fora junto com o ruído —
    o lockout entre repetições sumiria, e toda série viraria "extensão incompleta".
    """
    return min(_median_filter([signal(f) for f in frames]))


def _highest(frames: list[FrameSignals], signal: Callable[[FrameSignals], float]) -> float:
    """O maior valor do sinal no trecho. Ver [_lowest] para o porquê de não ser `max` cru."""
    return max(_median_filter([signal(f) for f in frames]))


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


def _window_radius(extremes: list[float]) -> float:
    """Meia-largura da janela do extremo, proporcional ao ritmo da série.

    Fixa em 0,5 s ela dizia coisas diferentes conforme a cadência. Numa repetição de 1,2 s
    cobria o movimento quase inteiro, e a "inclinação máxima no fundo" acabava lendo a subida
    junto; numa repetição cadenciada de 4 s pegava só uma lasca do fundo. Proporcional ao
    período, a janela passa a significar a mesma coisa nas duas.
    """
    if len(extremes) < 2:
        return DEFAULT_WINDOW_RADIUS_SEC
    period = statistics.median(b - a for a, b in zip(extremes, extremes[1:]))
    return min(MAX_WINDOW_RADIUS_SEC,
               max(MIN_WINDOW_RADIUS_SEC, period * WINDOW_RADIUS_FRACTION))


def _last_rep_truncated(extremes: list[float], times: list[float]) -> bool:
    """O vídeo acabou antes de a última repetição ter como voltar?

    A volta do movimento ocupa cerca de meio ciclo — do extremo até o extremo oposto. Se o que
    sobrou de vídeo depois do último extremo é menos que isso, a repetição não teve chance de
    completar, e aí ignorá-la se justifica. Se sobrou mais, a volta ESTÁ gravada e julgá-la é
    o certo: a última repetição é onde a fadiga cobra, e é a que mais tem o que ensinar.
    """
    if len(extremes) < 2:
        return True
    period = statistics.median(b - a for a, b in zip(extremes, extremes[1:]))
    return times[-1] - extremes[-1] < period / 2


def _window(frames: list[FrameSignals], center: float, radius: float) -> list[FrameSignals]:
    return [f for f in frames if abs(f.t - center) <= radius]


def _segment(frames: list[FrameSignals], start: float, end: float) -> list[FrameSignals]:
    return [f for f in frames if start <= f.t < end]


def analyze(spec: ExerciseSpec, frames: list[FrameSignals]) -> HeuristicResult:
    times = [f.t for f in frames]
    series = _smooth([spec.signal(f) for f in frames], times)
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

    radius = _window_radius(extremes)
    truncated = _last_rep_truncated(extremes, times)
    boundaries = extremes[1:] + [times[-1] + 1]
    reps = [
        Rep(t=t, window=_window(frames, t, radius), segment=_segment(frames, t, next_t))
        for t, next_t in zip(extremes, boundaries)
    ]
    reps = [r for r in reps if r.window]

    issues: list[Issue] = []
    correct_points: list[CorrectPoint] = []
    # O que cada checagem leu, tenha ela passado ou não. Sem isto, "sem pontos a melhorar" é
    # afirmação sem lastro: não dá para saber se a execução foi boa ou se um limite passou
    # raspando, e ajustar limite vira palpite.
    reports: list[dict] = []
    for check in spec.checks:
        skip = check.skip_last and truncated and len(reps) > 1
        checked = reps[:-1] if skip else reps
        failed_at = [round(r.t, 1) for r in checked if not check.passes(r)]
        if failed_at:
            issues.append(Issue(check.code, check.fail_message, failed_at))
        else:
            correct_points.append(CorrectPoint(check.code, check.ok_message))
        reports.append(check.report(checked, not failed_at))

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
        # Sem leitura nem folga: a comparação aqui é entre repetições, não contra um limite
        # fixo. As chaves ficam presentes, com None, para o consumidor não precisar saber de
        # que tipo de checagem veio cada entrada.
        reports.append({
            "code": series_check.code,
            "passed": not offenders,
            "reps_checked": len(reps),
            "slack": None,
            "readings": [],
        })

    return HeuristicResult(
        rep_count=len(extremes),
        issues=issues,
        correct_points=correct_points,
        metrics={
            f"min_{spec.signal_name}": round(min(series), 2),
            f"max_{spec.signal_name}": round(max(series), 2),
            "max_trunk_lean_deg": round(_highest(frames, _trunk), 1),
            # Vai dentro de `metrics` de propósito: o backend copia esse nó inteiro
            # (`HttpVisionClient.toCamelCase`) e o app o tipa como mapa livre, então a
            # instrumentação chega às duas pontas sem tocar em Java nem em Dart.
            "checks": reports,
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


def _trunk(f: FrameSignals) -> float:
    return f.trunk_angle


def _wrist_below_shoulder(f: FrameSignals) -> float:
    # Quanto o punho está ABAIXO do ombro; negativo quando passou dele.
    return f.wrist_y - f.shoulder_y


def _hip_below_knee(f: FrameSignals) -> float:
    # Positivo quando o quadril passou da linha do joelho (y cresce para baixo).
    return f.hip_y - f.knee_y


# Os quatro trechos de onde uma checagem lê. `window` é a janela em torno do extremo do
# movimento — o fundo do agachamento, o topo do press. `return` é o trecho que cobre a VOLTA,
# do extremo desta repetição até o da próxima: é onde vivem lockout, extensão e amplitude.

def _window_low(signal: Callable[[FrameSignals], float]) -> Callable[[Rep], float]:
    return lambda rep: _lowest(rep.window, signal)


def _window_high(signal: Callable[[FrameSignals], float]) -> Callable[[Rep], float]:
    return lambda rep: _highest(rep.window, signal)


def _return_low(signal: Callable[[FrameSignals], float]) -> Callable[[Rep], float]:
    return lambda rep: _lowest(rep.segment or rep.window, signal)


def _return_high(signal: Callable[[FrameSignals], float]) -> Callable[[Rep], float]:
    return lambda rep: _highest(rep.segment or rep.window, signal)


def _trunk_range(rep: Rep) -> float:
    """Quanto o tronco variou na repetição — a leitura de balanço, ou "roubo".

    É a mais sensível a ruído de todas: dois frames ruins, um em cada ponta, inventam um
    balanço que não houve. Daí os extremos robustos dos dois lados.
    """
    frames = rep.segment or rep.window
    return _highest(frames, _trunk) - _lowest(frames, _trunk)


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
    depths = [_lowest(rep.window, _knee) for rep in reps]
    deepest = min(depths)
    return [rep for rep, depth in zip(reps, depths) if depth - deepest > tolerance]


# ---------------------------------------------------------------------------
# Catálogo de exercícios suportados.

SPECS: dict[str, ExerciseSpec] = {
    "squat": ExerciseSpec(
        label="agachamento", signal=_knee, signal_name="knee_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "hip", "knee", "ankle"),
        checks=[
            # Profundidade tem duas leituras válidas, e basta uma passar: o ângulo do joelho e
            # a linha quadril-joelho. Cada uma é medida no PRÓPRIO extremo — o ponto mais fundo
            # pelo quadril pode cair um ou dois frames adiante do joelho mais fechado, e ler a
            # posição do quadril no instante escolhido pelo joelho respondia uma pergunta que
            # ninguém fez.
            Check("insufficient_depth",
                  "Profundidade insuficiente: desça até o quadril passar da linha do joelho.",
                  "Profundidade adequada — o quadril chegou à linha do joelho.",
                  [at_most(_window_low(_knee), 100, label="ângulo do joelho"),
                   at_least(_window_high(_hip_below_knee), -0.02,
                            unit="img", label="quadril vs. joelho")]),
            # 55° era quase um bom-dia: nessa inclinação o quadril já assumiu o movimento e a
            # barra saiu da linha do pé. 45 reprova o que precisa ser reprovado e ainda deixa
            # margem para quem tem fêmur longo, que agacha inclinado por anatomia e não por
            # erro — o agachamento medido nesta calibração fica em 30–34°.
            Check("excessive_trunk_lean",
                  "Inclinação excessiva do tronco na descida — mantenha o peito mais erguido.",
                  "Tronco firme na descida, sem inclinar demais.",
                  [at_most(_window_high(_trunk), 45)]),
            # Subir só até 165° já é joelho praticamente estendido; abaixo disso a pessoa
            # emendou a próxima repetição agachada, que é o erro que rouba a parte final do
            # movimento e cansa o quadríceps antes da hora.
            Check("incomplete_lockout",
                  "Você emenda a próxima repetição sem terminar de subir — estenda o joelho "
                  "por completo entre elas.",
                  "Extensão completa do joelho entre as repetições.",
                  [at_least(_return_high(_knee), 165)],
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
        joints=("shoulder", "hip", "knee", "ankle"),
        checks=[
            Check("insufficient_depth",
                  "Desça mais — o joelho da frente deve dobrar até cerca de 90°.",
                  "Boa amplitude na descida do afundo.",
                  [at_most(_window_low(_knee), 100)]),
            Check("excessive_trunk_lean",
                  "Tronco inclinando demais para a frente — mantenha-o ereto.",
                  "Tronco ereto durante o movimento.",
                  [at_most(_window_high(_trunk), 30)]),
        ]),
    "deadlift": ExerciseSpec(
        label="levantamento terra", signal=_hip, signal_name="hip_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "hip", "knee", "ankle"),
        checks=[
            Check("incomplete_lockout",
                  "Extensão de quadril incompleta no topo — finalize o movimento ereto.",
                  "Extensão completa de quadril no topo (lockout).",
                  [at_least(_return_high(_hip), 160)],
                  skip_last=True),
            Check("stiff_legs_at_start",
                  "Pernas quase esticadas na saída do chão — dobre mais os joelhos e use as pernas.",
                  "Boa flexão de pernas na saída do chão.",
                  [at_most(_window_low(_knee), 145)]),
        ]),
    "romanian_deadlift": ExerciseSpec(
        label="terra romeno", signal=_hip, signal_name="hip_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "hip", "knee", "ankle"),
        checks=[
            Check("incomplete_lockout",
                  "Extensão de quadril incompleta no topo — finalize o movimento ereto.",
                  "Extensão completa do quadril no topo.",
                  [at_least(_return_high(_hip), 160)],
                  skip_last=True),
            Check("excessive_knee_bend",
                  "Joelhos dobrando demais — no terra romeno, mantenha-os quase estendidos.",
                  "Joelhos firmes, com dobra mínima — bom padrão de dobradiça de quadril.",
                  [at_least(_window_low(_knee), 130)]),
        ]),
    "hip_thrust": ExerciseSpec(
        label="elevação de quadril", signal=_hip, signal_name="hip_angle_deg",
        extremum="top", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "hip", "knee"),
        checks=[
            Check("incomplete_extension",
                  "Suba mais o quadril — estenda por completo no topo do movimento.",
                  "Extensão completa do quadril no topo.",
                  [at_least(_window_high(_hip), 160)]),
            Check("short_range",
                  "Amplitude curta — desça mais o quadril entre as repetições.",
                  "Boa amplitude de movimento entre as repetições.",
                  [at_most(_return_low(_hip), 120)],
                  skip_last=True),
        ]),
    "back_extension": ExerciseSpec(
        # Banco romano: o ângulo do quadril é relativo às articulações,
        # então funciona com o corpo inclinado a 45°.
        label="extensão lombar", signal=_hip, signal_name="hip_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "hip", "knee"),
        checks=[
            Check("incomplete_extension",
                  "Suba até alinhar o tronco com as pernas — sem encurtar a subida.",
                  "Extensão completa no topo, tronco alinhado com as pernas.",
                  [at_least(_return_high(_hip), 160)],
                  skip_last=True),
            Check("short_range",
                  "Amplitude curta — desça o tronco com controle até perto da vertical.",
                  "Boa amplitude na descida.",
                  [at_most(_window_low(_hip), 130)]),
        ]),
    "bench_press": ExerciseSpec(
        label="supino", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist"),
        checks=[
            Check("short_range",
                  "Amplitude curta na descida — leve a barra até perto do peito.",
                  "Boa amplitude na descida da barra.",
                  [at_most(_window_low(_elbow), 100)]),
            Check("incomplete_lockout",
                  "Cotovelos não estenderam por completo no topo do movimento.",
                  "Extensão completa dos cotovelos no topo.",
                  [at_least(_return_high(_elbow), 160)],
                  skip_last=True),
        ]),
    "push_up": ExerciseSpec(
        label="flexão de braço", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        # O joelho entra porque `hip_sag` mede o alinhamento ombro-quadril-joelho: na prancha,
        # é ele que diz se o quadril caiu.
        joints=("shoulder", "elbow", "wrist", "hip", "knee"),
        checks=[
            Check("insufficient_depth",
                  "Desça mais — dobre os cotovelos até o peito se aproximar do chão.",
                  "Boa profundidade na descida.",
                  [at_most(_window_low(_elbow), 100)]),
            Check("hip_sag",
                  "Corpo desalinhado — quadril caindo ou empinando; contraia o abdômen e o glúteo.",
                  "Corpo alinhado durante toda a flexão, como uma prancha.",
                  [at_least(_return_low(_hip), 150)]),
        ]),
    "dips": ExerciseSpec(
        label="mergulho em paralelas", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist"),
        checks=[
            Check("insufficient_depth",
                  "Desça mais — dobre os cotovelos até cerca de 90°.",
                  "Boa profundidade na descida.",
                  [at_most(_window_low(_elbow), 100)]),
            Check("incomplete_lockout",
                  "Estenda os cotovelos por completo no topo do movimento.",
                  "Extensão completa dos cotovelos no topo.",
                  [at_least(_return_high(_elbow), 160)],
                  skip_last=True),
        ]),
    "triceps_pushdown": ExerciseSpec(
        # O extremo da rep é a EXTENSÃO do cotovelo (empurrão até embaixo).
        label="tríceps na polia", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="top", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_extension",
                  "Estenda o cotovelo por completo no fim do empurrão.",
                  "Extensão completa do cotovelo no fim do empurrão.",
                  [at_least(_window_high(_elbow), 160)]),
            Check("short_range",
                  "Amplitude curta — deixe o antebraço subir controlado até fechar o cotovelo.",
                  "Boa amplitude no retorno do movimento.",
                  [at_most(_return_low(_elbow), 100)],
                  skip_last=True),
            Check("torso_swing",
                  "Tronco debruçando sobre a polia para empurrar — mantenha o corpo parado.",
                  "Tronco estável — força só do tríceps.",
                  [at_most(_trunk_range, 15)]),
        ]),
    "overhead_press": ExerciseSpec(
        label="desenvolvimento", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_lockout",
                  "Cotovelos não estenderam por completo no topo do movimento.",
                  "Cotovelos estendidos por completo no topo.",
                  [at_least(_window_high(_elbow), 160)]),
            Check("excessive_back_lean",
                  "Tronco inclinando demais para trás — contraia o abdômen e o glúteo.",
                  "Tronco estável, sem inclinar para trás.",
                  [at_most(_window_high(_trunk), 25)]),
        ]),
    "lat_pulldown": ExerciseSpec(
        label="puxada alta", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — traga a barra até a altura do queixo ou do peito.",
                  "Puxada completa, com a barra chegando à altura do peito.",
                  [at_most(_window_low(_elbow), 90)]),
            Check("incomplete_extension",
                  "Estenda os braços por completo no retorno da barra.",
                  "Extensão completa dos braços no retorno.",
                  [at_least(_return_high(_elbow), 150)],
                  skip_last=True),
            Check("torso_swing",
                  "Tronco inclinando para trás para puxar — estabilize e puxe com as costas.",
                  "Tronco estável durante a puxada.",
                  [at_most(_trunk_range, 20)]),
        ]),
    "seated_cable_row": ExerciseSpec(
        label="remada baixa", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — leve o punho até o tronco.",
                  "Puxada completa, com o punho chegando ao tronco.",
                  [at_most(_window_low(_elbow), 90)]),
            Check("incomplete_extension",
                  "Estenda os braços por completo no retorno.",
                  "Extensão completa dos braços no retorno.",
                  [at_least(_return_high(_elbow), 150)],
                  skip_last=True),
            Check("torso_swing",
                  "Tronco balançando para frente e para trás — puxe com as costas, não com o embalo.",
                  "Tronco estável, sem embalo.",
                  [at_most(_trunk_range, 20)]),
        ]),
    "dumbbell_row": ExerciseSpec(
        label="remada serrote", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — suba o halter até a linha do tronco.",
                  "Puxada completa, com o halter chegando ao tronco.",
                  [at_most(_window_low(_elbow), 90)]),
            Check("incomplete_extension",
                  "Estenda o braço por completo na descida do halter.",
                  "Extensão completa do braço na descida.",
                  [at_least(_return_high(_elbow), 150)],
                  skip_last=True),
            Check("torso_swing",
                  "Tronco girando/balançando para ajudar — mantenha a posição apoiada e estável.",
                  "Tronco firme na posição apoiada.",
                  [at_most(_trunk_range, 15)]),
        ]),
    "barbell_row": ExerciseSpec(
        label="remada curvada", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_pull",
                  "Puxada incompleta — leve o cotovelo mais para trás, até a barra tocar o tronco.",
                  "Puxada completa, com a barra chegando ao tronco.",
                  [at_most(_window_low(_elbow), 90)]),
            Check("torso_swing",
                  "Tronco balançando para ajudar a puxada — estabilize a posição curvada.",
                  "Tronco estável na posição curvada durante toda a série.",
                  [at_most(_trunk_range, 20)]),
        ]),
    "biceps_curl": ExerciseSpec(
        label="rosca bíceps", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        # Sem joelho nem tornozelo: no vídeo de rosca desta calibração eles estavam FORA do
        # enquadramento e o MediaPipe os inventou, um deles com 97% de visibilidade declarada.
        # Exigi-los era exigir do usuário um enquadramento que a rosca não precisa.
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_curl",
                  "Flexão incompleta — suba o peso até o fim do movimento.",
                  "Flexão completa no topo do movimento.",
                  [at_most(_window_low(_elbow), 70)]),
            Check("incomplete_extension",
                  "Estenda o braço por completo entre as repetições.",
                  "Extensão completa do braço entre as repetições.",
                  [at_least(_return_high(_elbow), 150)],
                  skip_last=True),
            Check("torso_swing",
                  "Balanço de tronco (roubo) — mantenha o corpo parado e isole o bíceps.",
                  "Sem balanço de tronco — movimento isolado no bíceps.",
                  [at_most(_trunk_range, 15)]),
        ]),
    "hammer_curl": ExerciseSpec(
        label="rosca martelo", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("incomplete_curl",
                  "Flexão incompleta — suba o peso até o fim do movimento.",
                  "Flexão completa no topo do movimento.",
                  [at_most(_window_low(_elbow), 70)]),
            Check("incomplete_extension",
                  "Estenda o braço por completo entre as repetições.",
                  "Extensão completa do braço entre as repetições.",
                  [at_least(_return_high(_elbow), 150)],
                  skip_last=True),
            Check("torso_swing",
                  "Balanço de tronco (roubo) — mantenha o corpo parado e isole o braço.",
                  "Sem balanço de tronco — movimento isolado no braço.",
                  [at_most(_trunk_range, 15)]),
        ]),
    "preacher_curl": ExerciseSpec(
        # Braço apoiado no banco: sem checagem de balanço de tronco.
        label="rosca scott", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist"),
        checks=[
            Check("incomplete_curl",
                  "Flexão incompleta — suba o peso até o fim do movimento.",
                  "Flexão completa no topo do movimento.",
                  [at_most(_window_low(_elbow), 70)]),
            Check("incomplete_extension",
                  "Estenda o braço por completo na descida — sem repetições pela metade.",
                  "Extensão completa do braço na descida.",
                  [at_least(_return_high(_elbow), 150)],
                  skip_last=True),
        ]),
    "pull_up": ExerciseSpec(
        label="barra fixa", signal=_elbow, signal_name="elbow_angle_deg",
        extremum="bottom", min_range=MIN_SIGNAL_RANGE_DEG,
        joints=("shoulder", "elbow", "wrist"),
        checks=[
            Check("incomplete_pull",
                  "Subida incompleta — puxe até o queixo passar da linha da barra.",
                  "Subida completa, com boa flexão dos cotovelos.",
                  [at_most(_window_low(_elbow), 90)]),
            Check("incomplete_extension",
                  "Estenda os braços por completo na descida (dead hang).",
                  "Extensão completa dos braços na descida.",
                  [at_least(_return_high(_elbow), 160)],
                  skip_last=True),
        ]),
    "calf_raise": ExerciseSpec(
        label="panturrilha em pé", signal=_body_elevation, signal_name="body_elevation",
        extremum="top", min_range=MIN_SHRUG_TRAVEL,
        joints=("shoulder", "hip", "knee", "ankle"),
        checks=[
            Check("knee_bend",
                  "Joelhos dobrando durante a subida — mantenha-os estendidos para isolar a panturrilha.",
                  "Joelhos estendidos — o trabalho ficou na panturrilha.",
                  [at_least(_return_low(_knee), 160)]),
            Check("torso_swing",
                  "Corpo inclinando para ganhar impulso — suba na vertical, com controle.",
                  "Subida vertical e controlada, sem impulso.",
                  [at_most(_trunk_range, 10)]),
        ]),
    "shrug": ExerciseSpec(
        label="encolhimento", signal=_shoulder_elevation, signal_name="shoulder_elevation",
        extremum="top", min_range=MIN_SHRUG_TRAVEL,
        joints=("shoulder", "elbow", "wrist", "hip"),
        checks=[
            Check("elbow_bend",
                  "Cotovelos dobrando para ajudar — mantenha os braços estendidos e suba apenas os ombros.",
                  "Braços estendidos — o movimento ficou por conta do trapézio.",
                  [at_least(_return_low(_elbow), 150)]),
            Check("torso_swing",
                  "Impulso com o corpo — mantenha o tronco parado e encolha os ombros com controle.",
                  "Tronco estável durante o encolhimento.",
                  [at_most(_trunk_range, 10)]),
        ]),
    "front_raise": ExerciseSpec(
        # Elevação no plano sagital — a mais visível de todas na câmera lateral.
        label="elevação frontal", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        # O cotovelo não é lido em lugar nenhum aqui — o sinal é a altura do punho vs. o ombro.
        # Ele ainda aparece no overlay, por ser intermediário entre dois pontos lidos, mas não
        # tem poder de descartar frame.
        joints=("shoulder", "wrist", "hip"),
        checks=[
            Check("short_range",
                  "Suba os braços até a linha dos ombros.",
                  "Braços subindo até a linha dos ombros.",
                  [at_most(_window_low(_wrist_below_shoulder), 0.03, unit="img")]),
            Check("torso_swing",
                  "Balanço de tronco para impulsionar o peso — mantenha o corpo parado.",
                  "Sem balanço de tronco — movimento controlado.",
                  [at_most(_trunk_range, 12)]),
        ]),
    "upright_row": ExerciseSpec(
        label="remada alta", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        joints=("shoulder", "wrist", "hip"),
        checks=[
            Check("short_range",
                  "Puxada curta — suba a barra até a linha do peitoral superior, cotovelos na altura dos ombros.",
                  "Barra subindo até a linha do peitoral superior.",
                  [at_most(_window_low(_wrist_below_shoulder), 0.10, unit="img")]),
            Check("torso_swing",
                  "Balanço de tronco para impulsionar a barra — mantenha o corpo parado.",
                  "Sem balanço de tronco — puxada controlada.",
                  [at_most(_trunk_range, 15)]),
        ]),
    "lateral_raise": ExerciseSpec(
        label="elevação lateral", signal=_wrist_height, signal_name="wrist_height",
        extremum="top", min_range=MIN_WRIST_TRAVEL,
        joints=("shoulder", "wrist", "hip"),
        checks=[
            Check("short_range",
                  "Suba os braços até a linha dos ombros.",
                  "Braços subindo até a linha dos ombros.",
                  [at_most(_window_low(_wrist_below_shoulder), 0.03, unit="img")]),
            Check("torso_swing",
                  "Balanço de tronco para impulsionar o peso — mantenha o corpo parado.",
                  "Sem balanço de tronco — movimento controlado.",
                  [at_most(_trunk_range, 12)]),
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
