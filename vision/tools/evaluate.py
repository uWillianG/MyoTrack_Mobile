"""Mede a análise contra vídeos reais com gabarito.

Sem isto não dá para saber se um ajuste melhorou alguma coisa. `tests/test_heuristics.py`
alimenta senoides perfeitas e prova que as heurísticas são coerentes com elas — mas quase toda
a imprecisão que o usuário sente nasce ANTES, entre o vídeo e o `FrameSignals`: erro do
MediaPipe, câmera torta, articulação encoberta, lado trocado. Teste sintético não vê nada
disso, e limiar calibrado contra um vídeo é palpite com aparência de número.

Uso (dentro do container, que é onde o mediapipe existe):

    docker compose run --rm -v "$PWD/corpus:/corpus" vision python -m tools.evaluate /corpus

O diretório precisa de um `gabarito.json`:

    [
      {"file": "agacho-01.mp4", "exercise": "squat", "reps": 8,
       "issues": ["insufficient_depth"]},
      {"file": "agacho-02.mp4", "exercise": "squat", "reps": 5, "issues": [],
       "evaluable": false}
    ]

`issues` são os códigos que um avaliador humano diz estarem presentes na execução; todo código
que não aparece ali é cobrado como ausente, então vale preencher com cuidado. `evaluable:
false` marca o vídeo que a análise DEVE recusar (de frente, escuro, corpo cortado) — recusar
na hora certa conta tanto quanto acertar a nota.

O overlay não é gerado: ninguém o olha aqui, e pular o ffmpeg deixa a rodada bem mais rápida.
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

from app.analysis import BusinessError
from app.evaluation import UnsupportedExercise, evaluate


def analyse(corpus: Path, entry: dict) -> dict:
    """Roda um vídeo do corpus e devolve o que o gabarito precisa comparar."""
    row = {
        "file": entry["file"],
        "exercise": entry.get("exercise", "?"),
        "expected_reps": entry.get("reps"),
        "expected_issues": set(entry.get("issues", [])),
        "expected_evaluable": entry.get("evaluable", True),
        "reps": None,
        "issues": set(),
        "coverage": None,
        "frontality": None,
        "refused": False,
        "error": None,
    }

    video = corpus / entry["file"]
    if not video.exists():
        row["error"] = "arquivo não encontrado"
        return row

    try:
        result = evaluate(str(video), entry["exercise"])
    except (BusinessError, UnsupportedExercise) as error:
        # Recusa antes de chegar às heurísticas (vídeo longo, sem pessoa, formato ilegível).
        row["refused"] = True
        row["error"] = str(error)
        return row
    except Exception as error:  # noqa: BLE001 — uma falha não pode derrubar a rodada inteira
        row["error"] = f"{type(error).__name__}: {error}"
        return row

    row["reps"] = result["rep_count"]
    row["issues"] = {issue["code"] for issue in result["issues"]}
    row["coverage"] = result["metrics"].get("pose_coverage")
    row["frontality"] = result["metrics"].get("camera_frontality")
    row["refused"] = result["not_evaluable_reason"] is not None
    if row["refused"]:
        row["error"] = result["not_evaluable_reason"]
    return row


def report_videos(rows: list[dict]) -> None:
    print("POR VÍDEO")
    print(f"  {'arquivo':<28} {'exercício':<18} {'reps':>9} {'cob.':>6} {'front.':>7}  situação")
    for row in rows:
        reps = "—" if row["reps"] is None else f"{row['reps']}/{row['expected_reps']}"
        coverage = "—" if row["coverage"] is None else f"{row['coverage']:.2f}"
        frontality = "—" if row["frontality"] is None else f"{row['frontality']:.2f}"

        if row["error"] and not row["refused"]:
            situation = f"ERRO: {row['error']}"
        elif row["refused"]:
            expected = "" if not row["expected_evaluable"] else "  <-- não devia recusar"
            situation = f"recusou{expected}"
        elif not row["expected_evaluable"]:
            situation = "avaliou  <-- devia ter recusado"
        else:
            missed = row["expected_issues"] - row["issues"]
            extra = row["issues"] - row["expected_issues"]
            marks = ([f"-{code}" for code in sorted(missed)]
                     + [f"+{code}" for code in sorted(extra)])
            if row["expected_reps"] is not None and row["reps"] != row["expected_reps"]:
                marks.insert(0, "reps")
            situation = " ".join(marks) if marks else "ok"

        print(f"  {row['file']:<28} {row['exercise']:<18} {reps:>9} "
              f"{coverage:>6} {frontality:>7}  {situation}")
    print()


def report_reps(rows: list[dict]) -> None:
    """Erro de contagem, só sobre os vídeos que o gabarito diz avaliáveis e a análise avaliou."""
    by_exercise: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        if row["expected_evaluable"] and not row["refused"] and row["reps"] is not None:
            by_exercise[row["exercise"]].append(row)

    print("CONTAGEM DE REPETIÇÕES")
    if not by_exercise:
        print("  (nenhum vídeo avaliado)\n")
        return

    print(f"  {'exercício':<20} {'vídeos':>7} {'erro médio':>11} {'exatos':>8}")
    total, total_error, total_exact = 0, 0.0, 0
    for exercise in sorted(by_exercise):
        group = by_exercise[exercise]
        errors = [abs(r["reps"] - r["expected_reps"]) for r in group]
        exact = sum(1 for e in errors if e == 0)
        print(f"  {exercise:<20} {len(group):>7} {sum(errors) / len(errors):>11.2f} "
              f"{f'{exact}/{len(group)}':>8}")
        total += len(group)
        total_error += sum(errors)
        total_exact += exact

    print(f"  {'TOTAL':<20} {total:>7} {total_error / total:>11.2f} "
          f"{f'{total_exact}/{total}':>8}")
    print()


def report_checks(rows: list[dict]) -> None:
    """Precisão e recall por código de checagem.

    Recusar um vídeo que o gabarito diz avaliável entra aqui como falso negativo em cada
    ocorrência esperada: para quem gravou, "não deu para avaliar" e "não apontou o erro" são
    a mesma decepção.
    """
    counters: dict[str, dict[str, int]] = defaultdict(lambda: {"tp": 0, "fp": 0, "fn": 0})
    for row in rows:
        if not row["expected_evaluable"] or (row["error"] and not row["refused"]):
            continue
        for code in row["expected_issues"] | row["issues"]:
            if code in row["expected_issues"] and code in row["issues"]:
                counters[code]["tp"] += 1
            elif code in row["issues"]:
                counters[code]["fp"] += 1
            else:
                counters[code]["fn"] += 1

    print("CHECAGENS")
    if not counters:
        print("  (nenhuma ocorrência esperada nem apontada)\n")
        return

    ratio = lambda hits, total: f"{hits / total:.2f}" if total else "—"

    print(f"  {'código':<26} {'TP':>4} {'FP':>4} {'FN':>4} {'precisão':>9} {'recall':>8}")
    for code in sorted(counters):
        c = counters[code]
        print(f"  {code:<26} {c['tp']:>4} {c['fp']:>4} {c['fn']:>4} "
              f"{ratio(c['tp'], c['tp'] + c['fp']):>9} "
              f"{ratio(c['tp'], c['tp'] + c['fn']):>8}")
    print()


def report_refusals(rows: list[dict]) -> None:
    should = [r for r in rows if not r["expected_evaluable"]]
    refused_right = sum(1 for r in should if r["refused"])
    refused_wrong = [r for r in rows if r["expected_evaluable"] and r["refused"]]

    print("RECUSAS")
    print(f"  recusou e devia:     {refused_right}/{len(should)}")
    print(f"  recusou e não devia: {len(refused_wrong)}")
    for row in refused_wrong:
        print(f"    {row['file']}: {row['error']}")
    print()


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2

    corpus = Path(argv[1])
    gabarito = corpus / "gabarito.json"
    if not gabarito.exists():
        print(f"Sem gabarito em {gabarito}.")
        return 2

    entries = json.loads(gabarito.read_text(encoding="utf-8"))
    print(f"Analisando {len(entries)} vídeos de {corpus}...\n")
    rows = [analyse(corpus, entry) for entry in entries]

    report_videos(rows)
    report_reps(rows)
    report_checks(rows)
    report_refusals(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
