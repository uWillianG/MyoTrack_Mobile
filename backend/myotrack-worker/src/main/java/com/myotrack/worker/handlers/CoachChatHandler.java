package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.PlanStatus;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.CoachMessage;
import com.myotrack.domain.entity.DietPlan;
import com.myotrack.domain.entity.UserProfile;
import com.myotrack.domain.entity.WorkoutPlan;
import com.myotrack.domain.entity.WorkoutSession;
import com.myotrack.infrastructure.ai.AiUsageRecorder;
import com.myotrack.infrastructure.ai.LlmJsonClient;
import com.myotrack.infrastructure.ai.LlmJsonClient.LlmJsonResult;
import com.myotrack.infrastructure.repository.CoachMessageRepository;
import com.myotrack.infrastructure.repository.DietPlanRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import com.myotrack.infrastructure.repository.WorkoutPlanRepository;
import com.myotrack.infrastructure.repository.WorkoutSessionRepository;
import com.myotrack.worker.JobHandler;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Responde a pergunta do usuário ao coach.
 *
 * <p>Roda no Worker porque <b>toda chamada de LLM fica de um lado só</b>: a chave da API não
 * precisa existir na API, que é o processo exposto à internet.
 *
 * <p>O que faz a resposta valer alguma coisa é o contexto — perfil, planos ativos e as
 * últimas sessões. Sem ele o coach responderia como um chat genérico, e o usuário perceberia
 * na primeira pergunta que ele não sabe nada sobre o treino dele.
 */
@Component
public class CoachChatHandler implements JobHandler {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Mensagens recentes mandadas como transcrição. Além disso é token gasto à toa. */
    private static final Limit HISTORY = Limit.of(20);

    /** Sessões recentes no contexto: o suficiente para ver a tendência da semana. */
    private static final int RECENT_SESSIONS = 5;

    private final CoachMessageRepository messages;
    private final UserProfileRepository profiles;
    private final WorkoutPlanRepository workoutPlans;
    private final DietPlanRepository dietPlans;
    private final WorkoutSessionRepository sessions;
    private final AiUsageRecorder aiUsage;
    private final LlmJsonClient llm;

    public CoachChatHandler(
            CoachMessageRepository messages,
            UserProfileRepository profiles,
            WorkoutPlanRepository workoutPlans,
            DietPlanRepository dietPlans,
            WorkoutSessionRepository sessions,
            AiUsageRecorder aiUsage,
            LlmJsonClient llm) {
        this.messages = messages;
        this.profiles = profiles;
        this.workoutPlans = workoutPlans;
        this.dietPlans = dietPlans;
        this.sessions = sessions;
        this.aiUsage = aiUsage;
        this.llm = llm;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.COACH_CHAT;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        final UUID userId = job.getUserId();

        if (!llm.isConfigured()) {
            throw new IllegalStateException("O coach está indisponível no momento.");
        }

        final List<CoachMessage> history =
                new ArrayList<>(messages.findByUserIdOrderByCreatedAtDesc(userId, HISTORY));
        history.sort(Comparator.comparing(CoachMessage::getCreatedAt));

        // O job é criado logo depois de a pergunta ser gravada. Se a última mensagem não for
        // do usuário, algo saiu de ordem e responder produziria um monólogo do coach.
        if (history.isEmpty() || !history.getLast().isFromUser()) {
            throw new IllegalStateException("Não há pergunta do usuário para responder.");
        }

        final LlmJsonResult result =
                llm.generateJson(systemPrompt(), userPrompt(userId, history), replySchema());
        if (result == null) {
            // Instabilidade ou cota momentânea. Continua sendo transitória, mas o coach é
            // interativo: quem tenta de novo é quem perguntou, e a mensagem tem de dizer isso.
            throw new IllegalArgumentException(
                    "O coach não conseguiu responder agora. Tente perguntar de novo.");
        }

        recordUsage(userId, result);

        final String reply = replyFrom(result.json());
        if (reply == null || reply.isBlank()) {
            throw new IllegalArgumentException(
                    "O coach não conseguiu responder agora. Tente perguntar de novo.");
        }

        final CoachMessage answer = new CoachMessage();
        answer.setUserId(userId);
        answer.setFromUser(false);
        answer.setContent(reply.trim());

        return "{\"coachMessageId\":\"%s\"}".formatted(messages.save(answer).getId());
    }

    private static String replyFrom(String json) {
        try {
            return MAPPER.readTree(json).path("reply").asText(null);
        } catch (Exception e) {
            return null;
        }
    }

    private String userPrompt(UUID userId, List<CoachMessage> history) {
        final Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("contexto", context(userId));
        payload.put("conversa", history.stream().map(m -> Map.of(
                "de", m.isFromUser() ? "usuario" : "coach",
                "texto", m.getContent() == null ? "" : m.getContent())).toList());

        try {
            return MAPPER.writeValueAsString(payload);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao montar o contexto do coach.", e);
        }
    }

    /** Retrato compacto do usuário — o bastante para personalizar sem estourar tokens. */
    private Map<String, Object> context(UUID userId) {
        final Map<String, Object> context = new LinkedHashMap<>();

        profiles.findByUserId(userId).ifPresent(profile -> context.put("perfil", profileOf(profile)));

        workoutPlans.findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, PlanStatus.ACTIVE)
                .ifPresent(plan -> context.put("treino", workoutOf(plan)));

        dietPlans.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(p -> p.getStatus() == PlanStatus.ACTIVE)
                .findFirst()
                .ifPresent(plan -> context.put("dieta", dietOf(plan)));

        context.put("sessoesRecentes", sessions.findByUserIdOrderByDateDesc(userId).stream()
                .limit(RECENT_SESSIONS)
                .map(CoachChatHandler::sessionOf)
                .toList());

        return context;
    }

    private static Map<String, Object> profileOf(UserProfile profile) {
        final Map<String, Object> map = new LinkedHashMap<>();
        map.put("objetivo", profile.getGoal() == null ? null : profile.getGoal().getWireName());
        map.put("experiencia", profile.getExperienceLevel() == null
                ? null : profile.getExperienceLevel().getWireName());
        map.put("diasPorSemana", profile.getTrainingDaysPerWeek());
        map.put("restricoes", profile.getDietaryRestrictions());
        // Lesão é o que mais muda uma recomendação — vai explícito para o modelo não sugerir
        // um exercício que a pessoa não pode fazer.
        map.put("lesoes", profile.getInjuryNotes());
        return map;
    }

    private static Map<String, Object> workoutOf(WorkoutPlan plan) {
        return Map.of(
                "nome", plan.getName(),
                "divisao", plan.getSplit(),
                "dias", plan.getDays().stream()
                        .sorted(Comparator.comparingInt(d -> d.getOrder()))
                        .map(day -> Map.of(
                                "dia", day.getLabel(),
                                "exercicios", day.getExercises().stream()
                                        .map(e -> e.getExercise() == null
                                                ? "" : e.getExercise().getName())
                                        .toList()))
                        .toList());
    }

    private static Map<String, Object> dietOf(DietPlan plan) {
        final Map<String, Object> map = new LinkedHashMap<>();
        map.put("kcal", plan.getTargetKcal());
        map.put("proteinaG", plan.getTargetProteinG());
        map.put("carboidratoG", plan.getTargetCarbsG());
        map.put("gorduraG", plan.getTargetFatG());
        return map;
    }

    private static Map<String, Object> sessionOf(WorkoutSession session) {
        return Map.of(
                "data", String.valueOf(session.getDate()),
                "series", session.getSets().stream()
                        .map(set -> Map.of(
                                "exercicio", set.getExercise() == null
                                        ? "" : set.getExercise().getName(),
                                "reps", set.getReps(),
                                "cargaKg", set.getLoadKg()))
                        .toList());
    }

    private void recordUsage(UUID userId, LlmJsonResult result) {
        aiUsage.record(userId, AnalysisJobType.COACH_CHAT, llm, result);
    }

    /**
     * Prompt copiado do backend .NET.
     *
     * <p>As três primeiras regras não são estilo, são limite de responsabilidade: um app de
     * treino que opina sobre sintoma ou receita suplemento sai do que pode sustentar.
     */
    private static String systemPrompt() {
        return """
                Você é o coach virtual do MyoTrack, um app de treino e nutrição. Responda como um
                personal trainer e nutricionista: direto, motivador e prático, em português do Brasil.
                Personalize usando o contexto fornecido (perfil, planos e progressão do usuário).
                Regras:
                - Responda apenas sobre treino, nutrição, recuperação, hábitos e uso do app; fora
                  disso, redirecione com bom humor para os temas do coach.
                - Não diagnostique condições de saúde nem prescreva medicamentos ou suplementos;
                  em caso de dor persistente, lesão ou condição médica, recomende procurar um
                  profissional de saúde.
                - Não invente dados que não estejam no contexto; se não souber, diga que não sabe.
                - Seja conciso: no máximo ~150 palavras, texto corrido ou listas curtas, sem markdown.
                """;
    }

    private static Map<String, Object> replySchema() {
        final String schema = """
                {
                  "type": "object",
                  "properties": { "reply": { "type": "string" } },
                  "required": ["reply"]
                }
                """;
        try {
            @SuppressWarnings("unchecked")
            final Map<String, Object> parsed = MAPPER.readValue(schema, Map.class);
            return parsed;
        } catch (Exception e) {
            throw new IllegalStateException("Schema da resposta do coach inválido.", e);
        }
    }
}
