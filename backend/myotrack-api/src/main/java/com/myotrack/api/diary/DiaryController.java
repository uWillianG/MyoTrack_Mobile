package com.myotrack.api.diary;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.DietPlan;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Diário alimentar: consolida as análises de refeição do dia e compara o consumido com as
 * metas da dieta ativa. Porte de MyoTrack.Api/Controllers/DiaryController.cs.
 *
 * <p><b>O dia é o do fuso do cliente, não o UTC.</b> É o ponto central deste controller: um
 * jantar às 22h no Brasil já é o dia seguinte em UTC, e cortar por UTC jogaria a refeição para
 * o dia errado — o usuário veria a janta de ontem somando no almoço de hoje.
 */
@RestController
@RequestMapping("/api/diary")
public class DiaryController {

    /** Janela lida de uma vez: os 7 dias do gráfico. */
    private static final int WEEK_DAYS = 7;

    /**
     * Teto de análises carregadas. Uma semana não tem centenas; o limite evita que um
     * histórico grande seja puxado inteiro por causa de sete dias.
     */
    private static final Limit LOOKBACK = Limit.of(400);

    /** Mesma faixa do JS: ±14 horas cobre todos os fusos existentes. */
    private static final int MAX_TZ_MINUTES = 840;

    private final MealPhotoAnalysisRepository analyses;
    private final DietPlanRepository dietPlans;

    public DiaryController(
            MealPhotoAnalysisRepository analyses, DietPlanRepository dietPlans) {
        this.analyses = analyses;
        this.dietPlans = dietPlans;
    }

    /**
     * @param date dia local desejado; ausente = hoje no fuso do cliente
     * @param tz offset do fuso em minutos, na convenção do {@code getTimezoneOffset()} do
     *     JavaScript — Brasil (UTC−3) manda 180, e não −180
     */
    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<?> get(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(defaultValue = "0") int tz) {

        if (tz < -MAX_TZ_MINUTES || tz > MAX_TZ_MINUTES) {
            return ResponseEntity.badRequest().body(Map.of("error", "Fuso horário inválido."));
        }

        final UUID userId = CurrentUser.id();
        final LocalDate day = date != null
                ? date
                : OffsetDateTime.now(ZoneOffset.UTC).minusMinutes(tz).toLocalDate();

        final OffsetDateTime dayStart = startOf(day, tz);
        final OffsetDateTime dayEnd = dayStart.plusDays(1);
        final OffsetDateTime weekStart = dayStart.minusDays(WEEK_DAYS - 1L);

        final List<MealPhotoAnalysis> window =
                analyses.findByUserIdOrderByCreatedAtDesc(userId, LOOKBACK).stream()
                        .filter(a -> a.getCreatedAt() != null)
                        .filter(a -> !a.getCreatedAt().isBefore(weekStart)
                                && a.getCreatedAt().isBefore(dayEnd))
                        .sorted(java.util.Comparator.comparing(MealPhotoAnalysis::getCreatedAt))
                        .toList();

        final List<MealPhotoAnalysis> entries = window.stream()
                .filter(a -> !a.getCreatedAt().isBefore(dayStart))
                .toList();

        // Só o que está no diário soma: o excluído continua na lista, riscado, porque tirar
        // da tela esconderia do usuário a foto que ele mesmo mandou ignorar.
        final List<MealPhotoAnalysis> counted =
                entries.stream().filter(a -> !a.isExcludedFromDiary()).toList();

        return ResponseEntity.ok(new DiaryView(
                day,
                targetsFor(userId),
                new Macros(
                        sum(counted, MealPhotoAnalysis::getTotalKcal),
                        sum(counted, MealPhotoAnalysis::getTotalProteinG),
                        sum(counted, MealPhotoAnalysis::getTotalCarbsG),
                        sum(counted, MealPhotoAnalysis::getTotalFatG)),
                entries.stream().map(DiaryEntry::from).toList(),
                weekOf(day, tz, window)));
    }

    /** Inclui ou tira uma análise do diário — foto repetida, ou prato que não foi consumido. */
    @PutMapping("/entries/{id}")
    @Transactional
    public ResponseEntity<Void> setIncluded(
            @PathVariable UUID id, @RequestBody DiaryEntryUpdate body) {

        return analyses.findByIdAndUserId(id, CurrentUser.id())
                .map(analysis -> {
                    analysis.setExcludedFromDiary(!body.included());
                    analyses.save(analysis);
                    return ResponseEntity.noContent().<Void>build();
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /** Calorias por dia nos 7 dias que terminam no dia pedido. */
    private static List<DayTotal> weekOf(
            LocalDate day, int tz, List<MealPhotoAnalysis> window) {

        return java.util.stream.IntStream.range(0, WEEK_DAYS)
                .mapToObj(offset -> {
                    final LocalDate d = day.plusDays(offset - (WEEK_DAYS - 1L));
                    final OffsetDateTime start = startOf(d, tz);
                    final OffsetDateTime end = start.plusDays(1);

                    final BigDecimal kcal = window.stream()
                            .filter(a -> !a.isExcludedFromDiary())
                            .filter(a -> !a.getCreatedAt().isBefore(start)
                                    && a.getCreatedAt().isBefore(end))
                            .map(MealPhotoAnalysis::getTotalKcal)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    return new DayTotal(d, round(kcal));
                })
                .toList();
    }

    /**
     * Meia-noite local do dia, em UTC.
     *
     * <p>Soma o offset porque a convenção do {@code getTimezoneOffset()} é invertida: no
     * Brasil ele vale +180, e meia-noite local são 03:00 UTC.
     */
    private static OffsetDateTime startOf(LocalDate day, int tz) {
        return day.atTime(LocalTime.MIDNIGHT).atOffset(ZoneOffset.UTC).plusMinutes(tz);
    }

    private Macros targetsFor(UUID userId) {
        final DietPlan active = dietPlans.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(p -> p.getStatus() == PlanStatus.ACTIVE)
                .findFirst()
                .orElse(null);

        // Null e não zero: sem dieta gerada não há meta, e zero seria uma meta de jejum.
        return active == null ? null : new Macros(
                round(active.getTargetKcal()),
                round(active.getTargetProteinG()),
                round(active.getTargetCarbsG()),
                round(active.getTargetFatG()));
    }

    private static BigDecimal sum(
            List<MealPhotoAnalysis> items,
            java.util.function.Function<MealPhotoAnalysis, BigDecimal> field) {

        return round(items.stream()
                .map(field)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add));
    }

    /** Sem casa decimal: meio grama de proteína num prato estimado por foto é ruído. */
    private static BigDecimal round(BigDecimal value) {
        return value == null ? null : value.setScale(0, RoundingMode.HALF_UP);
    }

    public record DiaryEntryUpdate(boolean included) {
    }

    public record Macros(
            BigDecimal kcal, BigDecimal proteinG, BigDecimal carbsG, BigDecimal fatG) {
    }

    public record DayTotal(LocalDate date, BigDecimal kcal) {
    }

    public record DiaryEntry(
            UUID id,
            OffsetDateTime createdAt,
            BigDecimal totalKcal,
            BigDecimal totalProteinG,
            BigDecimal totalCarbsG,
            BigDecimal totalFatG,
            boolean userAdjusted,
            boolean excludedFromDiary) {

        static DiaryEntry from(MealPhotoAnalysis analysis) {
            return new DiaryEntry(
                    analysis.getId(),
                    analysis.getCreatedAt(),
                    round(analysis.getTotalKcal()),
                    round(analysis.getTotalProteinG()),
                    round(analysis.getTotalCarbsG()),
                    round(analysis.getTotalFatG()),
                    analysis.isUserAdjusted(),
                    analysis.isExcludedFromDiary());
        }
    }

    public record DiaryView(
            LocalDate date,
            Macros targets,
            Macros consumed,
            List<DiaryEntry> entries,
            List<DayTotal> week) {
    }
}
