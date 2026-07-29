package com.myotrack.domain;

import java.util.Arrays;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Exercícios que o serviço de visão sabe avaliar.
 *
 * <p>A lista espelha o dicionário {@code SPECS} do {@code vision/app/heuristics.py} — cada um
 * tem uma heurística própria (o que conta como profundidade num agachamento não vale para uma
 * rosca). Está duplicada aqui de propósito: sem ela, escolher um exercício sem suporte só
 * falharia depois de o usuário subir dezenas de MB de vídeo, e a mensagem viria do serviço
 * interno, em vez de a tela nem oferecer a opção.
 *
 * <p>O slug é o contrato com o serviço; o rótulo é o que o usuário lê.
 */
public enum VideoExercise {

    SQUAT("squat", "Agachamento"),
    LUNGE("lunge", "Afundo"),
    DEADLIFT("deadlift", "Levantamento terra"),
    ROMANIAN_DEADLIFT("romanian_deadlift", "Terra romeno"),
    HIP_THRUST("hip_thrust", "Elevação de quadril"),
    BACK_EXTENSION("back_extension", "Extensão lombar"),
    BENCH_PRESS("bench_press", "Supino"),
    PUSH_UP("push_up", "Flexão de braço"),
    DIPS("dips", "Mergulho em paralelas"),
    TRICEPS_PUSHDOWN("triceps_pushdown", "Tríceps na polia"),
    OVERHEAD_PRESS("overhead_press", "Desenvolvimento"),
    LAT_PULLDOWN("lat_pulldown", "Puxada alta"),
    SEATED_CABLE_ROW("seated_cable_row", "Remada baixa"),
    DUMBBELL_ROW("dumbbell_row", "Remada serrote"),
    BARBELL_ROW("barbell_row", "Remada curvada"),
    BICEPS_CURL("biceps_curl", "Rosca bíceps"),
    HAMMER_CURL("hammer_curl", "Rosca martelo"),
    PREACHER_CURL("preacher_curl", "Rosca scott"),
    PULL_UP("pull_up", "Barra fixa"),
    CALF_RAISE("calf_raise", "Panturrilha em pé"),
    SHRUG("shrug", "Encolhimento"),
    FRONT_RAISE("front_raise", "Elevação frontal"),
    UPRIGHT_ROW("upright_row", "Remada alta"),
    LATERAL_RAISE("lateral_raise", "Elevação lateral");

    private static final Map<String, VideoExercise> BY_SLUG = Arrays.stream(values())
            .collect(Collectors.toMap(VideoExercise::slug, Function.identity()));

    private final String slug;
    private final String label;

    VideoExercise(String slug, String label) {
        this.slug = slug;
        this.label = label;
    }

    public String slug() {
        return slug;
    }

    public String label() {
        return label;
    }

    public static Optional<VideoExercise> bySlug(String slug) {
        return Optional.ofNullable(slug).map(BY_SLUG::get);
    }
}
