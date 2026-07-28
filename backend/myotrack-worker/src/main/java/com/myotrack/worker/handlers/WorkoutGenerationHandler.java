package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.AiUsageLog;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.Exercise;
import com.myotrack.domain.entity.UserProfile;
import com.myotrack.domain.entity.WorkoutDay;
import com.myotrack.domain.entity.WorkoutExercise;
import com.myotrack.domain.entity.WorkoutPlan;
import com.myotrack.domain.service.LlmWorkoutValidator;
import com.myotrack.domain.service.LlmWorkoutValidator.LlmWorkout;
import com.myotrack.domain.service.WorkoutGeneration.GeneratedWorkout;
import com.myotrack.domain.service.WorkoutGeneration.Input;
import com.myotrack.domain.service.WorkoutRuleEngine;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.ai.TikTokVideoService;
import com.myotrack.infrastructure.repository.AiUsageLogRepository;
import com.myotrack.infrastructure.repository.ExerciseRepository;
import com.myotrack.infrastructure.repository.SetLogRepository;
import com.myotrack.infrastructure.repository.SetLogRepository.ExerciseProgression;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Component;
import com.myotrack.worker.JobHandler;
import org.springframework.transaction.annotation.Transactional;

/**
 * Gera o plano de treino. Porte de MyoTrack.Infrastructure/Ai/WorkoutGenerationService.cs.
 *
 * <p>Pipeline híbrida em três etapas, e a ordem importa:
 *
 * <ol>
 *   <li>O {@link WorkoutRuleEngine} monta um esqueleto <b>já válido</b> — split conforme os dias
 *       por semana, volume conforme o nível, sem exercício contraindicado.</li>
 *   <li>O LLM, se configurado, personaliza dentro desse esqueleto.</li>
 *   <li>O {@link LlmWorkoutValidator} confere a resposta contra o catálogo e faixas seguras.</li>
 * </ol>
 *
 * <p>Se qualquer coisa der errado no meio — sem chave de API, modelo fora do ar, resposta
 * inválida —, o esqueleto por regras é o resultado. <b>O usuário sempre recebe um treino.</b>
 */
@Component
public class WorkoutGenerationHandler implements JobHandler {

    private static final Logger log = LoggerFactory.getLogger(WorkoutGenerationHandler.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Oito semanas: o suficiente para ver progressão sem carregar treino antigo demais. */
    private static final int PROGRESSION_WINDOW_DAYS = 56;
    private static final Limit PROGRESSION_LIMIT = Limit.of(20);

    private final UserProfileRepository profiles;
    private final ExerciseRepository exercises;
    private final WorkoutPlanRepository plans;
    private final SetLogRepository setLogs;
    private final AiUsageLogRepository aiUsage;
    private final LlmJsonClient llm;
    private final TikTokVideoService tikTok;

    public WorkoutGenerationHandler(
            UserProfileRepository profiles,
            ExerciseRepository exercises,
            WorkoutPlanRepository plans,
            SetLogRepository setLogs,
            AiUsageLogRepository aiUsage,
            LlmJsonClient llm,
            TikTokVideoService tikTok) {
        this.profiles = profiles;
        this.exercises = exercises;
        this.plans = plans;
        this.setLogs = setLogs;
        this.aiUsage = aiUsage;
        this.llm = llm;
        this.tikTok = tikTok;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.WORKOUT_GENERATION;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        final UUID userId = job.getUserId();

        // IllegalStateException = erro de negócio: o poller falha o job sem reprocessar,
        // porque tentar de novo daria exatamente o mesmo resultado.
        final UserProfile profile = profiles.findByUserId(userId).orElseThrow(
                () -> new IllegalStateException(
                        "Perfil não encontrado. Complete o onboarding antes de gerar o treino."));

        final List<Exercise> catalog = exercises.findAll();
        final Input input = new Input(
                profile.getGoal(),
                profile.getExperienceLevel(),
                profile.getTrainingDaysPerWeek(),
                profile.getPriorityMuscleGroups(),
                List.of(profile.getInjuryTags()),
                profile.getAvailableEquipment());

        final GeneratedWorkout skeleton = WorkoutRuleEngine.generate(input, catalog);
        GeneratedWorkout plan = skeleton;
        String rawLlmOutput = null;

        if (llm.isConfigured()) {
            final LlmJsonResult result = personalize(profile, skeleton, catalog, userId);
            if (result != null) {
                rawLlmOutput = result.json();
                recordUsage(userId, result);

                final Optional<GeneratedWorkout> refined =
                        parseAndValidate(rawLlmOutput, skeleton, catalog, profile);
                if (refined.isPresent()) {
                    plan = refined.get();
                } else {
                    log.warn("Saída do LLM inválida para o usuário {}; mantendo o esqueleto por regras.",
                            userId);
                }
            }
        }

        final WorkoutPlan entity = persist(userId, profile, plan, input, rawLlmOutput);

        resolveTutorialVideos(plan, entity.getId());

        return "{\"workoutPlanId\":\"%s\"}".formatted(entity.getId());
    }

    private WorkoutPlan persist(
            UUID userId,
            UserProfile profile,
            GeneratedWorkout plan,
            Input input,
            String rawLlmOutput) {

        // Arquiva o plano ativo anterior: só pode haver um ativo por usuário, e é ele que a
        // tela de treino e o modo guiado carregam.
        final List<WorkoutPlan> previous = plans.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(p -> p.getStatus() == PlanStatus.ACTIVE)
                .toList();
        previous.forEach(p -> p.setStatus(PlanStatus.ARCHIVED));
        plans.saveAll(previous);

        final int version = plans.findByUserIdOrderByCreatedAtDesc(userId).size() + 1;

        final WorkoutPlan entity = new WorkoutPlan();
        entity.setUserId(userId);
        entity.setName("Treino %s v%d".formatted(plan.split(), version));
        entity.setGoal(profile.getGoal());
        entity.setSplit(plan.split());
        entity.setStatus(PlanStatus.ACTIVE);
        entity.setVersion(version);
        entity.setGenerationInputJson(toJson(input));
        entity.setRawLlmOutputJson(rawLlmOutput);

        final Map<Integer, Exercise> byId = new LinkedHashMap<>();
        exercises.findAll().forEach(e -> byId.put(e.getId(), e));

        for (final var day : plan.days()) {
            final WorkoutDay dayEntity = new WorkoutDay();
            dayEntity.setOrder(day.order());
            dayEntity.setLabel(day.label());

            int order = 1;
            for (final var exercise : day.exercises()) {
                final WorkoutExercise item = new WorkoutExercise();
                item.setExercise(byId.get(exercise.exerciseId()));
                item.setOrder(order++);
                item.setSets(exercise.sets());
                item.setRepsMin(exercise.repsMin());
                item.setRepsMax(exercise.repsMax());
                item.setRestSeconds(exercise.restSeconds());
                item.setNotes(exercise.notes());
                dayEntity.addExercise(item);
            }
            entity.addDay(dayEntity);
        }

        return plans.save(entity);
    }

    private LlmJsonResult personalize(
            UserProfile profile, GeneratedWorkout skeleton, List<Exercise> catalog, UUID userId) {

        final List<ExerciseProgression> progression = setLogs.summarizeProgression(
                userId, LocalDate.now().minusDays(PROGRESSION_WINDOW_DAYS), PROGRESSION_LIMIT);

        final List<String> injuries = List.of(profile.getInjuryTags());
        final List<Map<String, Object>> eligible = catalog.stream()
                .filter(e -> injuries.stream().noneMatch(tag -> List.of(e.getContraindicationTags())
                        .stream().anyMatch(t -> t.equalsIgnoreCase(tag))))
                .<Map<String, Object>>map(e -> Map.of(
                        "id", e.getId(),
                        "name", e.getName(),
                        "grupo", e.getPrimaryMuscleGroup().getWireName(),
                        "composto", e.isCompound()))
                .toList();

        // Prompt copiado literalmente do backend .NET: mudá-lo muda o comportamento da IA
        // em produção, e o texto foi ajustado contra saídas reais.
        final String system = """
                Você é um personal trainer experiente. Você recebe um esqueleto de treino gerado por regras
                e pode personalizá-lo: trocar exercícios por equivalentes da lista permitida, ajustar a ordem
                e escrever observações curtas e úteis em português para cada exercício.
                Regras invioláveis: use apenas exerciseId presentes na lista permitida; mantenha o mesmo número
                de dias; séries entre 2 e 5; repetições entre 5 e 30; descanso entre 30 e 240 segundos.
                Quando houver histórico de progressão, prefira manter os exercícios que o aluno já pratica com
                boa frequência e use as melhores cargas como referência nas observações (progressão gradual,
                nunca saltos maiores que ~10% de carga).
                """;

        final Map<String, Object> perfil = new LinkedHashMap<>();
        perfil.put("objetivo", profile.getGoal().getWireName());
        perfil.put("nivel", profile.getExperienceLevel().getWireName());
        perfil.put("diasPorSemana", profile.getTrainingDaysPerWeek());
        perfil.put("biotipo", profile.getBiotype() == null
                ? null : profile.getBiotype().getWireName());
        perfil.put("lesoes", profile.getInjuryNotes());
        perfil.put("gruposPriorizados", profile.getPriorityMuscleGroups().stream()
                .map(g -> g.getWireName()).toList());

        final Map<String, Object> user = new LinkedHashMap<>();
        user.put("perfil", perfil);
        user.put("progressaoRecente", progression.stream().map(p -> Map.of(
                "exercicio", p.exerciseName(),
                "melhorCargaKg", p.bestLoadKg(),
                "volumeTotalKg", p.volumeTotalKg(),
                "sessoes", p.sessions())).toList());
        user.put("esqueleto", skeleton);
        user.put("exerciciosPermitidos", eligible);

        return llm.generateJson(system, toJson(user), workoutSchema());
    }

    private Optional<GeneratedWorkout> parseAndValidate(
            String json, GeneratedWorkout skeleton, List<Exercise> catalog, UserProfile profile) {
        try {
            final LlmWorkout proposal = MAPPER.readValue(json, LlmWorkout.class);
            return LlmWorkoutValidator.validate(
                    proposal, skeleton, catalog, List.of(profile.getInjuryTags()));
        } catch (Exception e) {
            // JSON malformado é o mesmo caso de conteúdo inválido: fica o esqueleto.
            log.warn("Resposta do LLM não pôde ser lida: {}", e.getMessage());
            return Optional.empty();
        }
    }

    private void recordUsage(UUID userId, LlmJsonResult result) {
        final AiUsageLog usage = new AiUsageLog();
        usage.setUserId(userId);
        usage.setOperation(AnalysisJobType.WORKOUT_GENERATION);
        usage.setModel(llm.model());
        usage.setInputTokens(result.inputTokens());
        usage.setOutputTokens(result.outputTokens());
        aiUsage.save(usage);
    }

    /**
     * Vídeos explicativos: resolvidos uma vez por exercício e compartilhados por todos os
     * usuários. Melhor esforço — o treino já está salvo e não pode falhar por causa disto.
     */
    private void resolveTutorialVideos(GeneratedWorkout plan, UUID planId) {
        try {
            final List<Integer> ids = plan.days().stream()
                    .flatMap(d -> d.exercises().stream())
                    .map(e -> e.exerciseId())
                    .distinct()
                    .toList();
            tikTok.resolveMissing(ids);
        } catch (Exception e) {
            log.warn("Falha ao resolver vídeos do TikTok para o plano {}: {}", planId, e.getMessage());
        }
    }

    private static String toJson(Object value) {
        try {
            return MAPPER.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao serializar o payload da geração.", e);
        }
    }

    /**
     * JSON Schema da resposta. Copiado do .NET — é ele que garante que o modelo devolva a
     * estrutura esperada em vez de prosa.
     */
    private static Map<String, Object> workoutSchema() {
        final String schema = """
                {
                  "type": "object",
                  "properties": {
                    "days": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "order": { "type": "integer" },
                          "label": { "type": "string" },
                          "exercises": {
                            "type": "array",
                            "items": {
                              "type": "object",
                              "properties": {
                                "exerciseId": { "type": "integer" },
                                "sets": { "type": "integer" },
                                "repsMin": { "type": "integer" },
                                "repsMax": { "type": "integer" },
                                "restSeconds": { "type": "integer" },
                                "notes": { "type": "string" }
                              },
                              "required": ["exerciseId", "sets", "repsMin", "repsMax", "restSeconds"],
                              "additionalProperties": false
                            }
                          }
                        },
                        "required": ["order", "label", "exercises"],
                        "additionalProperties": false
                      }
                    }
                  },
                  "required": ["days"],
                  "additionalProperties": false
                }
                """;
        try {
            @SuppressWarnings("unchecked")
            final Map<String, Object> parsed = MAPPER.readValue(schema, Map.class);
            return parsed;
        } catch (Exception e) {
            throw new IllegalStateException("Schema do treino inválido.", e);
        }
    }
}
