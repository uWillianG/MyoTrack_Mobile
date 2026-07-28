package com.myotrack.infrastructure.seed;

import static com.myotrack.domain.Equipment.BARBELL;
import static com.myotrack.domain.Equipment.BODYWEIGHT;
import static com.myotrack.domain.Equipment.CABLE;
import static com.myotrack.domain.Equipment.DUMBBELL;
import static com.myotrack.domain.Equipment.KETTLEBELL;
import static com.myotrack.domain.Equipment.MACHINE;
import static com.myotrack.domain.Equipment.NONE;
import static com.myotrack.domain.Equipment.RESISTANCE_BAND;
import static com.myotrack.domain.MuscleGroup.ABS;
import static com.myotrack.domain.MuscleGroup.BACK;
import static com.myotrack.domain.MuscleGroup.BICEPS;
import static com.myotrack.domain.MuscleGroup.CALVES;
import static com.myotrack.domain.MuscleGroup.CARDIO;
import static com.myotrack.domain.MuscleGroup.CHEST;
import static com.myotrack.domain.MuscleGroup.FOREARMS;
import static com.myotrack.domain.MuscleGroup.FULL_BODY;
import static com.myotrack.domain.MuscleGroup.GLUTES;
import static com.myotrack.domain.MuscleGroup.HAMSTRINGS;
import static com.myotrack.domain.MuscleGroup.LOWER_BACK;
import static com.myotrack.domain.MuscleGroup.QUADRICEPS;
import static com.myotrack.domain.MuscleGroup.SHOULDERS;
import static com.myotrack.domain.MuscleGroup.TRAPS;
import static com.myotrack.domain.MuscleGroup.TRICEPS;

import com.myotrack.domain.Equipment;
import com.myotrack.domain.MuscleGroup;
import com.myotrack.domain.entity.Exercise;
import java.util.List;

/**
 * Catálogo inicial de exercícios. Porte de MyoTrack.Infrastructure/Seed/ExerciseSeed.cs —
 * a ordem dos itens define os ids gerados e, por tabela, a escolha do motor de regras;
 * reordenar muda os treinos de todo mundo.
 *
 * <p>Tags de contraindicação usam o vocabulário: knee, lower-back, shoulder, elbow, wrist, hip, neck.
 */
public final class ExerciseSeed {

    private ExerciseSeed() {
    }

    private static Exercise ex(
            String name, MuscleGroup primary, Equipment equipment, boolean compound,
            List<MuscleGroup> secondary, String... contraindications) {
        Exercise exercise = new Exercise();
        exercise.setName(name);
        exercise.setPrimaryMuscleGroup(primary);
        exercise.setEquipment(equipment);
        exercise.setCompound(compound);
        exercise.setSecondaryMuscleGroups(secondary == null ? List.of() : secondary);
        exercise.setContraindicationTags(contraindications);
        return exercise;
    }

    /** Uma instância nova a cada chamada — as entidades são mutáveis e vão para o EntityManager. */
    public static List<Exercise> items() {
        return List.of(
                // Peito
                ex("Supino reto com barra", CHEST, BARBELL, true, List.of(TRICEPS, SHOULDERS), "shoulder"),
                ex("Supino inclinado com halteres", CHEST, DUMBBELL, true, List.of(TRICEPS, SHOULDERS), "shoulder"),
                ex("Crucifixo na máquina (peck deck)", CHEST, MACHINE, false, null, "shoulder"),
                ex("Crossover na polia", CHEST, CABLE, false, null),
                ex("Flexão de braço", CHEST, BODYWEIGHT, true, List.of(TRICEPS, SHOULDERS), "wrist"),
                ex("Supino reto com halteres", CHEST, DUMBBELL, true, List.of(TRICEPS, SHOULDERS), "shoulder"),
                ex("Supino declinado com barra", CHEST, BARBELL, true, List.of(TRICEPS), "shoulder"),
                ex("Supino na máquina (chest press)", CHEST, MACHINE, true, List.of(TRICEPS)),
                ex("Crucifixo reto com halteres", CHEST, DUMBBELL, false, null, "shoulder"),
                ex("Flexão com pés elevados", CHEST, BODYWEIGHT, true, List.of(TRICEPS, SHOULDERS), "wrist", "shoulder"),
                ex("Pullover com halter", CHEST, DUMBBELL, false, List.of(BACK), "shoulder"),

                // Costas
                ex("Levantamento terra", BACK, BARBELL, true, List.of(HAMSTRINGS, GLUTES, LOWER_BACK), "lower-back", "knee"),
                ex("Barra fixa (pull-up)", BACK, BODYWEIGHT, true, List.of(BICEPS), "shoulder", "elbow"),
                ex("Puxada alta na polia (pulldown)", BACK, CABLE, true, List.of(BICEPS), "shoulder"),
                ex("Remada curvada com barra", BACK, BARBELL, true, List.of(BICEPS, LOWER_BACK), "lower-back"),
                ex("Remada baixa sentada", BACK, CABLE, true, List.of(BICEPS)),
                ex("Remada unilateral com halter (serrote)", BACK, DUMBBELL, true, List.of(BICEPS)),
                ex("Barra fixa pegada supinada (chin-up)", BACK, BODYWEIGHT, true, List.of(BICEPS), "shoulder", "elbow"),
                ex("Remada cavalinho (T-bar)", BACK, BARBELL, true, List.of(BICEPS, LOWER_BACK), "lower-back"),
                ex("Remada na máquina", BACK, MACHINE, true, List.of(BICEPS)),
                ex("Puxada na polia com pegada fechada (triângulo)", BACK, CABLE, true, List.of(BICEPS), "shoulder"),
                ex("Pullover na polia com braços estendidos", BACK, CABLE, false, null, "shoulder"),

                // Trapézio
                ex("Encolhimento com halteres (trapézio)", TRAPS, DUMBBELL, false, null, "neck"),
                ex("Encolhimento com barra", TRAPS, BARBELL, false, null, "neck"),
                ex("Encolhimento na barra guiada (Smith)", TRAPS, MACHINE, false, null, "neck"),
                ex("Encolhimento na polia baixa", TRAPS, CABLE, false, null, "neck"),
                ex("Remada alta na polia", TRAPS, CABLE, true, List.of(SHOULDERS, BICEPS), "shoulder", "wrist"),

                // Ombros
                ex("Desenvolvimento militar com barra", SHOULDERS, BARBELL, true, List.of(TRICEPS), "shoulder", "lower-back"),
                ex("Desenvolvimento com halteres sentado", SHOULDERS, DUMBBELL, true, List.of(TRICEPS), "shoulder"),
                ex("Elevação lateral com halteres", SHOULDERS, DUMBBELL, false, null, "shoulder"),
                ex("Elevação frontal com halteres", SHOULDERS, DUMBBELL, false, null, "shoulder"),
                ex("Crucifixo inverso na máquina", SHOULDERS, MACHINE, false, null),
                ex("Desenvolvimento na máquina", SHOULDERS, MACHINE, true, List.of(TRICEPS), "shoulder"),
                ex("Desenvolvimento Arnold com halteres", SHOULDERS, DUMBBELL, true, List.of(TRICEPS), "shoulder"),
                ex("Elevação lateral na polia", SHOULDERS, CABLE, false, null, "shoulder"),
                ex("Remada alta com barra", SHOULDERS, BARBELL, true, List.of(TRAPS, BICEPS), "shoulder", "wrist"),
                ex("Face pull na polia", SHOULDERS, CABLE, false, List.of(BACK)),

                // Bíceps
                ex("Rosca direta com barra", BICEPS, BARBELL, false, null, "elbow", "wrist"),
                ex("Rosca alternada com halteres", BICEPS, DUMBBELL, false, null, "elbow"),
                ex("Rosca martelo", BICEPS, DUMBBELL, false, List.of(FOREARMS)),
                ex("Rosca Scott na máquina", BICEPS, MACHINE, false, null, "elbow"),
                ex("Rosca concentrada", BICEPS, DUMBBELL, false, null, "elbow"),
                ex("Rosca na polia baixa", BICEPS, CABLE, false, null, "elbow"),
                ex("Rosca martelo no cabo (corda)", BICEPS, CABLE, false, List.of(FOREARMS)),
                ex("Rosca inversa com barra W", BICEPS, BARBELL, false, List.of(FOREARMS), "wrist", "elbow"),

                // Antebraços
                ex("Rosca de punho com barra", FOREARMS, BARBELL, false, null, "wrist"),
                ex("Extensão de punho com barra", FOREARMS, BARBELL, false, null, "wrist", "elbow"),
                ex("Rosca de punho com halter no banco", FOREARMS, DUMBBELL, false, null, "wrist"),
                ex("Rosca de punho na polia baixa", FOREARMS, CABLE, false, null, "wrist"),
                ex("Hand grip (alicate de força)", FOREARMS, NONE, false, null, "wrist"),

                // Tríceps
                ex("Tríceps na polia (pushdown)", TRICEPS, CABLE, false, null, "elbow"),
                ex("Tríceps testa com barra W", TRICEPS, BARBELL, false, null, "elbow"),
                ex("Tríceps francês com halter", TRICEPS, DUMBBELL, false, null, "elbow", "shoulder"),
                ex("Mergulho em paralelas (dips)", TRICEPS, BODYWEIGHT, true, List.of(CHEST, SHOULDERS), "shoulder", "elbow"),
                ex("Tríceps corda na polia", TRICEPS, CABLE, false, null, "elbow"),
                ex("Tríceps coice com halter (kickback)", TRICEPS, DUMBBELL, false, null, "elbow"),
                ex("Tríceps no banco (bench dips)", TRICEPS, BODYWEIGHT, true, List.of(SHOULDERS, CHEST), "shoulder", "wrist"),
                ex("Extensão de tríceps na máquina", TRICEPS, MACHINE, false, null, "elbow"),

                // Quadríceps
                ex("Agachamento livre com barra", QUADRICEPS, BARBELL, true, List.of(GLUTES, HAMSTRINGS, LOWER_BACK), "knee", "lower-back", "hip"),
                ex("Leg press 45°", QUADRICEPS, MACHINE, true, List.of(GLUTES), "knee"),
                ex("Cadeira extensora", QUADRICEPS, MACHINE, false, null, "knee"),
                ex("Afundo com halteres", QUADRICEPS, DUMBBELL, true, List.of(GLUTES), "knee"),
                ex("Agachamento búlgaro", QUADRICEPS, DUMBBELL, true, List.of(GLUTES), "knee"),
                ex("Agachamento no hack", QUADRICEPS, MACHINE, true, List.of(GLUTES), "knee"),
                ex("Agachamento goblet com halter", QUADRICEPS, DUMBBELL, true, List.of(GLUTES), "knee"),
                ex("Avanço caminhando com halteres", QUADRICEPS, DUMBBELL, true, List.of(GLUTES, HAMSTRINGS), "knee"),

                // Posteriores
                ex("Stiff com barra", HAMSTRINGS, BARBELL, true, List.of(GLUTES, LOWER_BACK), "lower-back"),
                ex("Mesa flexora", HAMSTRINGS, MACHINE, false, null, "knee"),
                ex("Cadeira flexora", HAMSTRINGS, MACHINE, false, null, "knee"),
                ex("Terra romeno com halteres", HAMSTRINGS, DUMBBELL, true, List.of(GLUTES, LOWER_BACK), "lower-back"),
                ex("Bom dia com barra", HAMSTRINGS, BARBELL, true, List.of(LOWER_BACK, GLUTES), "lower-back"),
                ex("Flexora em pé unilateral", HAMSTRINGS, MACHINE, false, null, "knee"),

                // Glúteos
                ex("Elevação pélvica (hip thrust)", GLUTES, BARBELL, true, List.of(HAMSTRINGS), "hip"),
                ex("Cadeira abdutora", GLUTES, MACHINE, false, null),
                ex("Coice na polia (glúteo)", GLUTES, CABLE, false, null),
                ex("Ponte de glúteos no solo", GLUTES, BODYWEIGHT, false, List.of(HAMSTRINGS)),
                ex("Agachamento sumô com halter", GLUTES, DUMBBELL, true, List.of(QUADRICEPS, HAMSTRINGS), "knee"),
                ex("Abdução de quadril com faixa elástica", GLUTES, RESISTANCE_BAND, false, null),

                // Lombar
                ex("Extensão lombar no banco romano (hiperextensão)", LOWER_BACK, MACHINE, false, List.of(GLUTES, HAMSTRINGS), "lower-back"),
                ex("Superman no solo", LOWER_BACK, BODYWEIGHT, false, List.of(GLUTES)),

                // Panturrilhas
                ex("Panturrilha em pé na máquina", CALVES, MACHINE, false, null),
                ex("Panturrilha sentado", CALVES, MACHINE, false, null),
                ex("Panturrilha em pé com halteres", CALVES, DUMBBELL, false, null),
                ex("Panturrilha no leg press", CALVES, MACHINE, false, null),
                ex("Panturrilha em pé no degrau (peso corporal)", CALVES, BODYWEIGHT, false, null),
                ex("Panturrilha unilateral no degrau com halter", CALVES, DUMBBELL, false, null),

                // Abdômen
                ex("Prancha abdominal", ABS, BODYWEIGHT, false, null, "lower-back", "shoulder"),
                ex("Abdominal supra no solo", ABS, BODYWEIGHT, false, null, "neck", "lower-back"),
                ex("Abdominal na polia alta (crunch)", ABS, CABLE, false, null),
                ex("Elevação de pernas suspenso", ABS, BODYWEIGHT, false, null, "lower-back", "shoulder"),
                ex("Prancha lateral (oblíquos)", ABS, BODYWEIGHT, false, null, "shoulder"),
                ex("Rotação de tronco sentado (russian twist)", ABS, BODYWEIGHT, false, null, "lower-back"),
                ex("Elevação de pernas deitado", ABS, BODYWEIGHT, false, null, "lower-back"),
                ex("Abdominal na máquina", ABS, MACHINE, false, null),

                // Cardio / condicionamento
                ex("Esteira — corrida contínua", CARDIO, MACHINE, false, null, "knee", "hip"),
                ex("Bicicleta ergométrica", CARDIO, MACHINE, false, null),
                ex("Remo ergômetro", CARDIO, MACHINE, true, List.of(BACK), "lower-back"),
                ex("Elíptico (transport)", CARDIO, MACHINE, false, null),
                ex("Pular corda", CARDIO, BODYWEIGHT, false, null, "knee"),
                ex("Burpee", FULL_BODY, BODYWEIGHT, true, null, "knee", "wrist", "lower-back"),
                ex("Kettlebell swing", FULL_BODY, KETTLEBELL, true, List.of(GLUTES, LOWER_BACK), "lower-back"));
    }
}
