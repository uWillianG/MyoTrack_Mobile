package com.myotrack.api.profile;

import com.myotrack.domain.Biotype;
import com.myotrack.domain.ConsentType;
import com.myotrack.domain.Equipment;
import com.myotrack.domain.ExperienceLevel;
import com.myotrack.domain.FitnessGoal;
import com.myotrack.domain.MuscleGroup;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Contratos de /api/profile. Os nomes de campo são os mesmos do .NET. */
public final class ProfileDtos {

    private ProfileDtos() {
    }

    /**
     * Dados do onboarding.
     *
     * <p>Quase tudo é opcional: o usuário pode pular a maior parte e ainda receber um treino,
     * porque o motor de regras tem padrão para tudo. Só {@code experienceLevel}, {@code goal} e
     * {@code trainingDaysPerWeek} moldam o plano de verdade.
     */
    public record ProfileRequest(
            LocalDate birthDate,
            String sex,
            BigDecimal heightCm,
            Biotype biotype,
            ExperienceLevel experienceLevel,
            FitnessGoal goal,
            int trainingDaysPerWeek,
            List<MuscleGroup> priorityMuscleGroups,
            String injuryNotes,
            List<String> injuryTags,
            List<Equipment> availableEquipment,
            List<String> dietaryRestrictions,
            List<String> foodPreferences) {
    }

    public record ConsentRequest(ConsentType type, String termsVersion) {
    }
}
