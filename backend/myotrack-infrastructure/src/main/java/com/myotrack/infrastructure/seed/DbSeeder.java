package com.myotrack.infrastructure.seed;

import com.myotrack.domain.entity.Exercise;
import com.myotrack.infrastructure.identity.AppRoles;
import com.myotrack.infrastructure.identity.ApplicationRole;
import com.myotrack.infrastructure.repository.ApplicationRoleRepository;
import com.myotrack.infrastructure.repository.ExerciseRepository;
import com.myotrack.infrastructure.repository.FoodItemRepository;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Semeia papéis e catálogos no startup. Porte de MyoTrack.Infrastructure/Seed/DbSeeder.cs.
 *
 * <p>É idempotente e roda a cada boot: itens novos do catálogo entram também em bancos já
 * populados, sem passo manual de banco.
 */
@Component
public class DbSeeder {

    private static final Logger log = LoggerFactory.getLogger(DbSeeder.class);

    private final ApplicationRoleRepository roles;
    private final ExerciseRepository exercises;
    private final FoodItemRepository foods;

    public DbSeeder(ApplicationRoleRepository roles, ExerciseRepository exercises, FoodItemRepository foods) {
        this.roles = roles;
        this.exercises = exercises;
        this.foods = foods;
    }

    @Transactional
    public void seed() {
        seedRoles();
        seedExercises();
        seedFoods();
    }

    private void seedRoles() {
        for (String name : AppRoles.ALL) {
            String normalized = name.toUpperCase(Locale.ROOT);
            if (roles.findByNormalizedName(normalized).isEmpty()) {
                ApplicationRole role = new ApplicationRole();
                role.setName(name);
                role.setNormalizedName(normalized);
                role.setConcurrencyStamp(java.util.UUID.randomUUID().toString());
                roles.save(role);
                log.info("Papel '{}' criado.", name);
            }
        }
    }

    /**
     * Idempotente por nome. Além de inserir os que faltam, sincroniza a classificação muscular
     * dos existentes com o seed — o seed é a fonte da verdade do catálogo (ex.: o encolhimento
     * migrou de Back para Traps e os planos antigos precisam ver a mudança).
     */
    private void seedExercises() {
        Map<String, Exercise> existingByName = new HashMap<>();
        for (Exercise exercise : exercises.findAll()) {
            existingByName.put(exercise.getName().toLowerCase(Locale.ROOT), exercise);
        }

        List<Exercise> toSave = new java.util.ArrayList<>();
        for (Exercise seed : ExerciseSeed.items()) {
            Exercise existing = existingByName.get(seed.getName().toLowerCase(Locale.ROOT));
            if (existing == null) {
                toSave.add(seed);
            } else if (existing.getPrimaryMuscleGroup() != seed.getPrimaryMuscleGroup()
                    || !existing.getSecondaryMuscleGroups().equals(seed.getSecondaryMuscleGroups())) {
                existing.setPrimaryMuscleGroup(seed.getPrimaryMuscleGroup());
                existing.setSecondaryMuscleGroups(seed.getSecondaryMuscleGroups());
                toSave.add(existing);
            }
        }

        if (!toSave.isEmpty()) {
            exercises.saveAll(toSave);
            log.info("Catálogo de exercícios sincronizado ({} registros).", toSave.size());
        }
    }

    /** Diferente dos exercícios, os alimentos só entram uma vez: o usuário pode ter editado. */
    private void seedFoods() {
        if (foods.count() == 0) {
            foods.saveAll(FoodSeed.items());
            log.info("Catálogo de alimentos semeado.");
        }
    }
}
