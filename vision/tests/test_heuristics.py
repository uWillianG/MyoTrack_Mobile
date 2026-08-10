"""Testa as heurísticas do vision com séries sintéticas de FrameSignals.

Importa heuristics.py isoladamente (sem mediapipe/cv2, que não estão instalados
localmente) simulando o módulo analysis com um FrameSignals equivalente.
"""

import math
import sys
import types
from dataclasses import dataclass, replace
from pathlib import Path

VISION = Path(__file__).resolve().parents[1]


@dataclass
class FrameSignals:
    t: float
    knee_angle: float
    hip_angle: float
    elbow_angle: float
    trunk_angle: float
    hip_y: float
    knee_y: float
    shoulder_y: float
    wrist_y: float


# Injeta um pacote "app" fake com app.analysis.FrameSignals para satisfazer o import relativo.
app_pkg = types.ModuleType("app")
app_pkg.__path__ = [str(VISION / "app")]
analysis_mod = types.ModuleType("app.analysis")
analysis_mod.FrameSignals = FrameSignals
sys.modules["app"] = app_pkg
sys.modules["app.analysis"] = analysis_mod

import importlib

heuristics = importlib.import_module("app.heuristics")

FPS = 12.0


def series(reps: int, frame_at, period: float = 3.0):
    """Gera `reps` ciclos senoidais de `period` s chamando frame_at(t, phase 0..1)."""
    frames = []
    for i in range(int(reps * period * FPS)):
        t = i / FPS
        phase = math.sin(math.pi * ((t % period) / period))  # 0 no início/fim, 1 no meio da rep
        frames.append(frame_at(t, phase))
    return frames


def hold_after(frames, seconds):
    """Segue gravando depois da última repetição, parado na posição em que ela terminou."""
    last = frames[-1]
    return frames + [
        replace(last, t=last.t + (i + 1) / FPS) for i in range(int(seconds * FPS))
    ]


def with_glitch(frames, at_t, **overrides):
    """Estraga UM frame, como o MediaPipe faz quando perde um landmark por um instante."""
    return [
        replace(f, **overrides) if abs(f.t - at_t) < 0.5 / FPS else f
        for f in frames
    ]


def neutral(t, *, knee=175, hip=170, elbow=170, trunk=10, hip_y=0.5, knee_y=0.7, shoulder_y=0.25, wrist_y=0.8):
    return FrameSignals(t, knee, hip, elbow, trunk, hip_y, knee_y, shoulder_y, wrist_y)


def make_squat(reps, min_knee, trunk_at_bottom, deep, top_knee=175):
    """`top_knee` é até onde o joelho estende ENTRE as repetições — o lockout."""
    return series(reps, lambda t, d: neutral(
        t, knee=top_knee - (top_knee - min_knee) * d, hip=170 - 80 * d,
        trunk=10 + (trunk_at_bottom - 10) * d, hip_y=0.5 + (0.25 if deep else 0.12) * d))


def make_squat_fading(depths, trunk_at_bottom=30):
    """Série em que cada repetição tem a própria profundidade.

    É o que `make_squat` não sabe fazer: lá todas as repetições são iguais, e uma série
    uniforme nunca exercita a checagem que compara umas com as outras.
    """
    def frame_at(t, d):
        rep = min(int(t // 3.0), len(depths) - 1)
        min_knee = depths[rep]
        return neutral(
            t, knee=175 - (175 - min_knee) * d, hip=170 - 80 * d,
            trunk=10 + (trunk_at_bottom - 10) * d, hip_y=0.5 + 0.25 * d)

    return series(len(depths), frame_at)


def make_fast_squat(reps, period):
    """Agachamento de cadência rápida, com um instante parado no topo e no fundo.

    A senoide de `make_squat` passa pelo extremo em UM frame. A 12 fps, numa repetição de 1 s,
    isso não é extremo de movimento nenhum — é pico de uma amostra só, indistinguível de erro
    do MediaPipe. Achatar as pontas modela a parada que existe de verdade entre a descida e a
    subida, e é o que torna o caso comparável a um vídeo real de série rápida.
    """
    def frame_at(t, d):
        flat = min(1.0, max(0.0, (d - 0.25) / 0.5))
        return neutral(t, knee=175 - 105 * flat, hip=170 - 80 * flat,
                       trunk=10 + 20 * flat, hip_y=0.5 + 0.25 * flat)

    return series(reps, frame_at, period=period)


def make_deadlift(reps, top_hip, knee_at_bottom=135):
    return series(reps, lambda t, d: neutral(
        t, knee=175 - (175 - knee_at_bottom) * d, hip=top_hip - (top_hip - 90) * d, trunk=15 + 55 * d))


def make_press(reps, top_elbow, trunk_lean):
    return series(reps, lambda t, d: neutral(
        t, elbow=90 + (top_elbow - 90) * d, trunk=5 + (trunk_lean - 5) * d,
        shoulder_y=0.45, wrist_y=0.45 - 0.30 * d, hip_y=0.55, knee_y=0.75))


def make_curl(reps, top_flex, bottom_ext, trunk_swing):
    return series(reps, lambda t, d: neutral(
        t, elbow=bottom_ext - (bottom_ext - top_flex) * d, trunk=8 + trunk_swing * d))


def make_pushup(reps, bottom_elbow, hip_line):
    return series(reps, lambda t, d: neutral(
        t, elbow=175 - (175 - bottom_elbow) * d, hip=180 - (180 - hip_line) * d, trunk=80))


def make_hip_thrust(reps, top_hip, bottom_hip):
    return series(reps, lambda t, d: neutral(t, hip=bottom_hip + (top_hip - bottom_hip) * d, trunk=60))


def make_lateral_raise(reps, top_wrist_above_shoulder, trunk_swing):
    # Punho parte da altura do quadril (0.55) e sobe até perto da linha do ombro (0.30).
    return series(reps, lambda t, d: neutral(
        t, trunk=5 + trunk_swing * d, shoulder_y=0.30,
        wrist_y=0.55 - (0.25 + top_wrist_above_shoulder) * d))


def make_shrug(reps, elbow, trunk_swing):
    # Ombro sobe ~0.04 normalizado (amplitude típica de encolhimento).
    return series(reps, lambda t, d: neutral(
        t, elbow=elbow, trunk=5 + trunk_swing * d, shoulder_y=0.25 - 0.04 * d))


def make_calf_raise(reps, knee_at_top, trunk_swing):
    # Corpo inteiro sobe ~0.04 normalizado (quadril acompanha o calcanhar).
    return series(reps, lambda t, d: neutral(
        t, knee=175 - (175 - knee_at_top) * d, trunk=5 + trunk_swing * d,
        hip_y=0.50 - 0.04 * d))


def run(exercise, frames):
    return heuristics.HEURISTICS[exercise](frames)


ok = True


def check(name, condition, detail=""):
    global ok
    status = "OK " if condition else "FALHOU"
    print(f"[{status}] {name} {detail}")
    ok &= condition
    return condition


def codes(result):
    return [i.code for i in result.issues]


def ok_codes(result):
    return [p.code for p in result.correct_points]


# --- Agachamento -----------------------------------------------------------
r = run("squat", make_squat(5, min_knee=70, trunk_at_bottom=35, deep=True))
check("squat bom: 5 reps", r.rep_count == 5, f"(reps={r.rep_count})")
check("squat bom: sem issues", not r.issues, f"(issues={codes(r)})")
check("squat bom: 4 pontos corretos", len(r.correct_points) == 4, f"(ok={ok_codes(r)})")
check("squat bom: score 100", heuristics.compute_score(r) == 100)

r = run("squat", make_squat(4, min_knee=120, trunk_at_bottom=30, deep=False))
check("squat raso: detecta insufficient_depth", "insufficient_depth" in codes(r), f"(issues={codes(r)})")
check("squat raso: tronco ainda e ponto correto", "excessive_trunk_lean" in ok_codes(r), f"(ok={ok_codes(r)})")
check("squat raso: score < 100", (heuristics.compute_score(r) or 100) < 100)

r = run("squat", make_squat(4, min_knee=75, trunk_at_bottom=70, deep=True))
check("squat inclinado: detecta excessive_trunk_lean", "excessive_trunk_lean" in codes(r), f"(issues={codes(r)})")

# O limiar de tronco desceu de 55 para 45. Estes dois casos prendem a linha nova: 50 reprova
# hoje e passava antes, 40 continua passando. Sem eles, alguém "arredonda" o número de volta.
r = run("squat", make_squat(4, min_knee=75, trunk_at_bottom=50, deep=True))
check("squat tronco 50: reprova (limiar 45)", "excessive_trunk_lean" in codes(r), f"(issues={codes(r)})")
r = run("squat", make_squat(4, min_knee=75, trunk_at_bottom=40, deep=True))
check("squat tronco 40: passa", "excessive_trunk_lean" in ok_codes(r), f"(ok={ok_codes(r)})")

# Lockout: o joelho só volta a 150° entre as repetições, ou seja, a pessoa emenda agachada.
r = run("squat", make_squat(4, min_knee=70, trunk_at_bottom=30, deep=True, top_knee=150))
check("squat sem lockout: detecta incomplete_lockout", "incomplete_lockout" in codes(r), f"(issues={codes(r)})")
check("squat sem lockout: score < 100", (heuristics.compute_score(r) or 100) < 100)

# E a ÚLTIMA repetição fica fora da conta: o segmento dela vai até o fim do vídeo, então quem
# terminou a série e parou reprovaria sempre. Com 4 reps ruins, são 3 ocorrências, não 4.
check("squat sem lockout: a ultima rep nao conta",
      len([i for i in r.issues if i.code == "incomplete_lockout"][0].timestamps_sec) == 3,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'incomplete_lockout']})")

# Profundidade que decai: as duas primeiras fundas, as duas últimas encurtando.
r = run("squat", make_squat_fading([70, 75, 95, 100]))
check("squat encurtando: detecta inconsistent_depth", "inconsistent_depth" in codes(r), f"(issues={codes(r)})")
check("squat encurtando: aponta as duas ultimas",
      len([i for i in r.issues if i.code == "inconsistent_depth"][0].timestamps_sec) == 2,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'inconsistent_depth']})")

r = run("squat", make_squat_fading([70, 74, 72, 71]))
check("squat constante: sem inconsistent_depth", "inconsistent_depth" in ok_codes(r), f"(ok={ok_codes(r)})")

# Com duas repetições não há série para comparar, e apontar uma delas seria inventar.
r = run("squat", make_squat_fading([70, 120]))
check("squat com 2 reps: consistencia nao acusa", "inconsistent_depth" in ok_codes(r), f"(ok={ok_codes(r)})")

# O caso que o detector antigo perdia. Ele normalizava pela faixa do vídeo e só fechava ciclo
# abaixo de 35% dela: as duas repetições rasas não cruzavam esse corte e sumiam da contagem —
# quatro agachamentos viravam DOIS, e a consistência não tinha o que apontar. As piores
# repetições eram justamente as que desapareciam.
r = run("squat", make_squat_fading([70, 72, 105, 120]))
check("squat muito raso no fim: conta as 4 repeticoes", r.rep_count == 4, f"(reps={r.rep_count})")
check("squat muito raso no fim: acusa a inconsistencia", "inconsistent_depth" in codes(r), f"(issues={codes(r)})")
check("squat muito raso no fim: aponta as duas rasas",
      len([i for i in r.issues if i.code == "inconsistent_depth"][0].timestamps_sec) == 2,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'inconsistent_depth']})")

r = run("squat", [neutral(i / FPS) for i in range(60)])
check("squat parado: nao avaliavel", r.not_evaluable_reason is not None and r.rep_count == 0)
check("squat parado: score None", heuristics.compute_score(r) is None)
check("squat parado: sem pontos corretos", not r.correct_points)

# --- Levantamento terra ----------------------------------------------------
r = run("deadlift", make_deadlift(3, top_hip=175))
check("terra bom: 3 reps", r.rep_count == 3, f"(reps={r.rep_count})")
check("terra bom: sem issues", not r.issues, f"(issues={codes(r)})")
check("terra bom: lockout como ponto correto", "incomplete_lockout" in ok_codes(r), f"(ok={ok_codes(r)})")

r = run("deadlift", make_deadlift(3, top_hip=150))
check("terra sem lockout: detecta incomplete_lockout", "incomplete_lockout" in codes(r), f"(issues={codes(r)})")

r = run("deadlift", make_deadlift(3, top_hip=175, knee_at_bottom=170))
check("terra de pernas retas: detecta stiff_legs_at_start", "stiff_legs_at_start" in codes(r), f"(issues={codes(r)})")

# --- Terra romeno (o inverso: joelhos DEVEM ficar quase retos) -------------
r = run("romanian_deadlift", make_deadlift(3, top_hip=175, knee_at_bottom=160))
check("RDL bom: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("romanian_deadlift", make_deadlift(3, top_hip=175, knee_at_bottom=100))
check("RDL com joelho dobrando: detecta excessive_knee_bend", "excessive_knee_bend" in codes(r), f"(issues={codes(r)})")

# --- Desenvolvimento -------------------------------------------------------
r = run("overhead_press", make_press(4, top_elbow=175, trunk_lean=8))
check("press bom: 4 reps", r.rep_count == 4, f"(reps={r.rep_count})")
check("press bom: sem issues", not r.issues, f"(issues={codes(r)})")
check("press bom: 2 pontos corretos", len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("overhead_press", make_press(4, top_elbow=140, trunk_lean=35))
check("press ruim: detecta incomplete_lockout", "incomplete_lockout" in codes(r), f"(issues={codes(r)})")
check("press ruim: detecta excessive_back_lean", "excessive_back_lean" in codes(r), f"(issues={codes(r)})")
check("press ruim: sem pontos corretos", not r.correct_points, f"(ok={ok_codes(r)})")

# --- Supino ----------------------------------------------------------------
r = run("bench_press", make_curl(4, top_flex=80, bottom_ext=175, trunk_swing=0))
check("supino bom: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("bench_press", make_curl(4, top_flex=120, bottom_ext=175, trunk_swing=0))
check("supino raso: detecta short_range", "short_range" in codes(r), f"(issues={codes(r)})")

# --- Flexão de braço -------------------------------------------------------
r = run("push_up", make_pushup(4, bottom_elbow=80, hip_line=175))
check("flexao boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("push_up", make_pushup(4, bottom_elbow=80, hip_line=130))
check("flexao com quadril caido: detecta hip_sag", "hip_sag" in codes(r), f"(issues={codes(r)})")

# --- Mergulho em paralelas -------------------------------------------------
r = run("dips", make_curl(4, top_flex=80, bottom_ext=175, trunk_swing=0))
check("dips bom: sem issues e 2 pontos corretos", not r.issues and len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("dips", make_curl(4, top_flex=120, bottom_ext=150, trunk_swing=0))
check("dips raso: detecta insufficient_depth e incomplete_lockout",
      "insufficient_depth" in codes(r) and "incomplete_lockout" in codes(r), f"(issues={codes(r)})")

# --- Tríceps na polia ------------------------------------------------------
r = run("triceps_pushdown", make_curl(4, top_flex=70, bottom_ext=175, trunk_swing=0))
check("pushdown bom: sem issues", not r.issues, f"(issues={codes(r)})")
check("pushdown bom: 3 pontos corretos", len(r.correct_points) == 3, f"(ok={ok_codes(r)})")

r = run("triceps_pushdown", make_curl(4, top_flex=110, bottom_ext=145, trunk_swing=25))
check("pushdown ruim: detecta incomplete_extension", "incomplete_extension" in codes(r), f"(issues={codes(r)})")
check("pushdown ruim: detecta short_range", "short_range" in codes(r), f"(issues={codes(r)})")
check("pushdown ruim: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

# --- Rosca bíceps ----------------------------------------------------------
r = run("biceps_curl", make_curl(4, top_flex=50, bottom_ext=170, trunk_swing=0))
check("rosca boa: sem issues", not r.issues, f"(issues={codes(r)})")
check("rosca boa: 3 pontos corretos", len(r.correct_points) == 3, f"(ok={ok_codes(r)})")

r = run("biceps_curl", make_curl(4, top_flex=90, bottom_ext=130, trunk_swing=25))
check("rosca ruim: detecta incomplete_curl", "incomplete_curl" in codes(r), f"(issues={codes(r)})")
check("rosca ruim: detecta incomplete_extension", "incomplete_extension" in codes(r), f"(issues={codes(r)})")
check("rosca ruim: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

# --- Barra fixa ------------------------------------------------------------
r = run("pull_up", make_curl(4, top_flex=60, bottom_ext=175, trunk_swing=0))
check("barra fixa boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("pull_up", make_curl(4, top_flex=110, bottom_ext=140, trunk_swing=0))
check("barra fixa curta: detecta incomplete_pull e incomplete_extension",
      "incomplete_pull" in codes(r) and "incomplete_extension" in codes(r), f"(issues={codes(r)})")

# --- Puxada alta / remadas -------------------------------------------------
r = run("lat_pulldown", make_curl(4, top_flex=70, bottom_ext=170, trunk_swing=0))
check("puxada alta boa: sem issues", not r.issues, f"(issues={codes(r)})")
check("puxada alta boa: 3 pontos corretos", len(r.correct_points) == 3, f"(ok={ok_codes(r)})")

r = run("lat_pulldown", make_curl(4, top_flex=110, bottom_ext=170, trunk_swing=30))
check("puxada alta ruim: detecta incomplete_pull", "incomplete_pull" in codes(r), f"(issues={codes(r)})")
check("puxada alta ruim: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

r = run("seated_cable_row", make_curl(4, top_flex=70, bottom_ext=170, trunk_swing=0))
check("remada baixa boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("seated_cable_row", make_curl(4, top_flex=70, bottom_ext=130, trunk_swing=0))
check("remada baixa sem retorno: detecta incomplete_extension", "incomplete_extension" in codes(r), f"(issues={codes(r)})")

r = run("dumbbell_row", make_curl(4, top_flex=70, bottom_ext=170, trunk_swing=0))
check("serrote bom: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("dumbbell_row", make_curl(4, top_flex=70, bottom_ext=170, trunk_swing=25))
check("serrote com balanco: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

# --- Rosca martelo / Scott --------------------------------------------------
r = run("hammer_curl", make_curl(4, top_flex=50, bottom_ext=170, trunk_swing=0))
check("martelo boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("hammer_curl", make_curl(4, top_flex=90, bottom_ext=170, trunk_swing=25))
check("martelo ruim: detecta incomplete_curl e torso_swing",
      "incomplete_curl" in codes(r) and "torso_swing" in codes(r), f"(issues={codes(r)})")

r = run("preacher_curl", make_curl(4, top_flex=50, bottom_ext=170, trunk_swing=0))
check("scott boa: sem issues e 2 pontos corretos", not r.issues and len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("preacher_curl", make_curl(4, top_flex=50, bottom_ext=120, trunk_swing=0))
check("scott sem estender: detecta incomplete_extension", "incomplete_extension" in codes(r), f"(issues={codes(r)})")

# --- Remada curvada --------------------------------------------------------
r = run("barbell_row", make_curl(4, top_flex=70, bottom_ext=170, trunk_swing=0))
check("remada boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("barbell_row", make_curl(4, top_flex=110, bottom_ext=170, trunk_swing=30))
check("remada ruim: detecta incomplete_pull", "incomplete_pull" in codes(r), f"(issues={codes(r)})")
check("remada ruim: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

# --- Elevação de quadril ---------------------------------------------------
r = run("hip_thrust", make_hip_thrust(4, top_hip=175, bottom_hip=100))
check("hip thrust bom: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("hip_thrust", make_hip_thrust(4, top_hip=145, bottom_hip=100))
check("hip thrust sem extensao: detecta incomplete_extension", "incomplete_extension" in codes(r), f"(issues={codes(r)})")

# --- Elevação lateral ------------------------------------------------------
r = run("lateral_raise", make_lateral_raise(4, top_wrist_above_shoulder=0.0, trunk_swing=0))
check("elevacao lateral boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("lateral_raise", make_lateral_raise(4, top_wrist_above_shoulder=-0.10, trunk_swing=20))
check("elevacao lateral curta: detecta short_range", "short_range" in codes(r), f"(issues={codes(r)})")
check("elevacao lateral com balanco: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

# --- Elevação frontal / remada alta ----------------------------------------
r = run("front_raise", make_lateral_raise(4, top_wrist_above_shoulder=0.0, trunk_swing=0))
check("elevacao frontal boa: sem issues e 2 pontos corretos",
      not r.issues and len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("front_raise", make_lateral_raise(4, top_wrist_above_shoulder=-0.10, trunk_swing=20))
check("elevacao frontal curta: detecta short_range e torso_swing",
      "short_range" in codes(r) and "torso_swing" in codes(r), f"(issues={codes(r)})")

r = run("upright_row", make_lateral_raise(4, top_wrist_above_shoulder=-0.05, trunk_swing=0))
check("remada alta boa: sem issues", not r.issues, f"(issues={codes(r)})")

r = run("upright_row", make_lateral_raise(4, top_wrist_above_shoulder=-0.13, trunk_swing=25))
check("remada alta curta: detecta short_range", "short_range" in codes(r), f"(issues={codes(r)})")
check("remada alta com balanco: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

# --- Encolhimento (trapézio) ------------------------------------------------
r = run("shrug", make_shrug(4, elbow=175, trunk_swing=0))
check("encolhimento bom: 4 reps", r.rep_count == 4, f"(reps={r.rep_count})")
check("encolhimento bom: sem issues e 2 pontos corretos",
      not r.issues and len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("shrug", make_shrug(4, elbow=120, trunk_swing=15))
check("encolhimento ruim: detecta elbow_bend", "elbow_bend" in codes(r), f"(issues={codes(r)})")
check("encolhimento ruim: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

r = run("shrug", [neutral(i / FPS) for i in range(60)])
check("encolhimento parado: nao avaliavel", r.not_evaluable_reason is not None)

# --- Extensão lombar (banco romano) -----------------------------------------
r = run("back_extension", make_hip_thrust(4, top_hip=175, bottom_hip=95))
check("extensao lombar boa: sem issues e 2 pontos corretos",
      not r.issues and len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("back_extension", make_hip_thrust(4, top_hip=150, bottom_hip=95))
check("extensao lombar sem subir: detecta incomplete_extension", "incomplete_extension" in codes(r), f"(issues={codes(r)})")

r = run("back_extension", make_hip_thrust(4, top_hip=175, bottom_hip=140))
check("extensao lombar curta: detecta short_range", "short_range" in codes(r), f"(issues={codes(r)})")

# --- Panturrilha em pé ------------------------------------------------------
r = run("calf_raise", make_calf_raise(4, knee_at_top=175, trunk_swing=0))
check("panturrilha boa: 4 reps", r.rep_count == 4, f"(reps={r.rep_count})")
check("panturrilha boa: sem issues e 2 pontos corretos",
      not r.issues and len(r.correct_points) == 2, f"(ok={ok_codes(r)})")

r = run("calf_raise", make_calf_raise(4, knee_at_top=145, trunk_swing=15))
check("panturrilha ruim: detecta knee_bend", "knee_bend" in codes(r), f"(issues={codes(r)})")
check("panturrilha ruim: detecta torso_swing", "torso_swing" in codes(r), f"(issues={codes(r)})")

r = run("calf_raise", [neutral(i / FPS) for i in range(60)])
check("panturrilha parada: nao avaliavel", r.not_evaluable_reason is not None)

# --- Robustez a frame estragado ---------------------------------------------
# As checagens leem o EXTREMO da repetição, então um frame chutado pelo MediaPipe valia por
# toda a repetição. Estes casos prendem os extremos robustos: um frame não decide mais nada.

r = run("squat", with_glitch(
    make_squat(4, min_knee=120, trunk_at_bottom=30, deep=False), at_t=1.5, knee_angle=60))
check("squat raso com 1 frame chutado: continua raso nas 4 reps",
      "insufficient_depth" in codes(r)
      and len([i for i in r.issues if i.code == "insufficient_depth"][0].timestamps_sec) == 4,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'insufficient_depth']})")
check("squat raso com 1 frame chutado: nao inventa repeticao", r.rep_count == 4,
      f"(reps={r.rep_count})")

# Amplitude de tronco é a leitura mais sensível de todas: um pico sozinho inventava o balanço.
r = run("biceps_curl", with_glitch(
    make_curl(4, top_flex=50, bottom_ext=170, trunk_swing=0), at_t=3.0, trunk_angle=60))
check("rosca com 1 frame chutado: nao acusa balanco", "torso_swing" in ok_codes(r),
      f"(issues={codes(r)})")
check("rosca com 1 frame chutado: segue sem issues", not r.issues, f"(issues={codes(r)})")

# --- A última repetição nas checagens de retorno ------------------------------
# O `segment` da última vai até o fim do vídeo, e quem larga o peso depois da última rosca
# nunca "volta". Sem a flag, essa repetição reprovava sempre — falso positivo sistemático,
# e logo na última, que é onde o usuário menos duvida do app.
r = run("biceps_curl", make_curl(4, top_flex=50, bottom_ext=130, trunk_swing=0))
check("rosca sem estender: detecta incomplete_extension",
      "incomplete_extension" in codes(r), f"(issues={codes(r)})")
check("rosca sem estender: a ultima rep nao conta",
      len([i for i in r.issues if i.code == "incomplete_extension"][0].timestamps_sec) == 3,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'incomplete_extension']})")

# Mas quem continuou gravando tem a volta REGISTRADA, e aí a última é julgada como qualquer
# outra. Ignorá-la sempre escondia o erro mais provável da série: a última é onde a fadiga
# cobra, e era exatamente ela que sumia do relatório.
r = run("biceps_curl", hold_after(
    make_curl(4, top_flex=50, bottom_ext=130, trunk_swing=0), seconds=2.0))
check("rosca sem estender, camera ligada ate o fim: 4 reps", r.rep_count == 4,
      f"(reps={r.rep_count})")
check("rosca sem estender, camera ligada ate o fim: conta as 4",
      len([i for i in r.issues if i.code == "incomplete_extension"][0].timestamps_sec) == 4,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'incomplete_extension']})")

# E a linha para de valer nas checagens que exigem MANTER algo ao longo do trecho: ali o vídeo
# acabar cedo só tira a chance de reprovar, e pular a última custaria detecção de graça.
r = run("push_up", make_pushup(4, bottom_elbow=80, hip_line=130))
check("flexao com quadril caido: conta as 4 reps",
      len([i for i in r.issues if i.code == "hip_sag"][0].timestamps_sec) == 4,
      f"(marcas={[i.timestamps_sec for i in r.issues if i.code == 'hip_sag']})")

# --- Janela do extremo proporcional à cadência -------------------------------
# A meia-largura era fixa em 0,5 s, e por isso dizia coisas diferentes conforme a cadência:
# numa repetição de 1 s cobria o movimento inteiro, e a "janela do fundo" lia a subida junto.
check("janela: cadencia rapida encurta a janela",
      heuristics._window_radius([0.0, 1.2, 2.4, 3.6]) == 0.3,
      f"(raio={heuristics._window_radius([0.0, 1.2, 2.4, 3.6])})")
check("janela: cadencia lenta para no teto",
      heuristics._window_radius([0.0, 4.0, 8.0]) == 0.75,
      f"(raio={heuristics._window_radius([0.0, 4.0, 8.0])})")
check("janela: com uma repeticao so, nao ha periodo para medir",
      heuristics._window_radius([1.5]) == 0.5,
      f"(raio={heuristics._window_radius([1.5])})")

r = run("squat", make_fast_squat(4, period=1.0))
check("squat rapido: 4 reps", r.rep_count == 4, f"(reps={r.rep_count})")
check("squat rapido bem executado: sem issues", not r.issues, f"(issues={codes(r)})")

# E a cadência lenta continua enxergando o que é de fato do fundo.
r = run("squat", make_squat(4, min_knee=75, trunk_at_bottom=70, deep=True))
check("squat lento inclinado no fundo: continua acusando",
      "excessive_trunk_lean" in codes(r), f"(issues={codes(r)})")

# --- Instrumentação: o que cada checagem leu ---------------------------------
# Sem isto, "sem pontos a melhorar" não é auditável: não dá para distinguir execução boa de
# limite que passou raspando, e mexer no limite vira palpite.

def checks_of(result):
    return {c["code"]: c for c in result.metrics["checks"]}


r = run("squat", make_squat(5, min_knee=70, trunk_at_bottom=35, deep=True))
check("instrumentacao: uma entrada por checagem", len(r.metrics["checks"]) == 4,
      f"(n={len(r.metrics['checks'])})")
check("instrumentacao: profundidade traz as duas leituras",
      len(checks_of(r)["insufficient_depth"]["readings"]) == 2,
      f"(leituras={checks_of(r)['insufficient_depth']['readings']})")
lean = checks_of(r)["excessive_trunk_lean"]["readings"][0]
check("instrumentacao: leitura traz limite, comparacao e unidade",
      lean["limit"] == 45 and lean["comparison"] == "at_most" and lean["unit"] == "deg",
      f"({lean})")
check("instrumentacao: checagem de serie entra sem leitura",
      checks_of(r)["inconsistent_depth"]["readings"] == []
      and checks_of(r)["inconsistent_depth"]["slack"] is None)

# O caso que motivou tudo: passou, mas por 5°. Antes disso o relatório dizia só "profundidade
# adequada", e não havia como saber que o limite estava decidindo no fio.
r = run("squat", make_squat(4, min_knee=95, trunk_at_bottom=30, deep=False))
depth = checks_of(r)["insufficient_depth"]
check("instrumentacao: profundidade no limite vira ponto correto",
      depth["passed"] and "insufficient_depth" in ok_codes(r), f"(issues={codes(r)})")
check("instrumentacao: e a folga mostra que passou raspando", 0 < depth["slack"] < 6,
      f"(folga={depth['slack']})")

r = run("squat", make_squat(4, min_knee=120, trunk_at_bottom=30, deep=False))
depth = checks_of(r)["insufficient_depth"]
check("instrumentacao: reprovada tem folga negativa",
      not depth["passed"] and depth["slack"] < 0, f"(folga={depth['slack']})")

# O veredito TEM de sair da mesma conta que a folga — é o ponto de derivar o booleano da
# medição em vez de calcular a leitura por fora. Os valores abaixo ficam colados nos limites
# de propósito, para o invariante ser exercitado perto do zero.
for exercise, frames in [
    ("squat", make_squat(4, min_knee=95, trunk_at_bottom=44, deep=False)),
    ("biceps_curl", make_curl(4, top_flex=69, bottom_ext=151, trunk_swing=14)),
    ("deadlift", make_deadlift(3, top_hip=161)),
    ("push_up", make_pushup(4, bottom_elbow=99, hip_line=151)),
]:
    for c in run(exercise, frames).metrics["checks"]:
        if c["slack"] is None:
            continue
        check(f"instrumentacao: {exercise}/{c['code']} veredito bate com a folga",
              c["passed"] == (c["slack"] >= 0),
              f"(passed={c['passed']}, folga={c['slack']})")

# --- Catálogo completo -----------------------------------------------------
check("catalogo: 24 exercicios", len(heuristics.HEURISTICS) == 24, f"(n={len(heuristics.HEURISTICS)})")

print()
print("TODOS OS TESTES PASSARAM" if ok else "HA FALHAS")
sys.exit(0 if ok else 1)
