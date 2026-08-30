package com.myotrack.infrastructure.seed;

import com.myotrack.domain.entity.Exercise;
import com.myotrack.infrastructure.identity.AppRoles;
import com.myotrack.infrastructure.identity.ApplicationRole;
import com.myotrack.infrastructure.repository.ApplicationRoleRepository;
import com.myotrack.infrastructure.repository.ExerciseRepository;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Semeia papéis e o catálogo de exercícios no startup. Porte de
 * MyoTrack.Infrastructure/Seed/DbSeeder.cs.
 *
 * <p>É idempotente e roda a cada boot: itens novos do catálogo entram também em bancos já
 * populados, sem passo manual de banco.
 *
 * <p><b>O catálogo de alimentos saiu daqui</b> e passou a ser semeado por migração Flyway
 * ({@code V8__food_catalog_seed.sql}). Ele nunca teve a sincronização que os exercícios têm: a
 * guarda era {@code if (count() == 0)}, o que faz o seed valer uma vez e depois congelar — um
 * alimento acrescentado à lista nunca chegava a um banco que já tivesse alimentos, e a lista Java
 * passava a descrever um catálogo que só existia em máquina nova. Migração resolve exatamente
 * isso: roda uma vez por banco, na ordem, e o que ela afirma é o que está lá.
 */
@Component
public class DbSeeder {

    private static final Logger log = LoggerFactory.getLogger(DbSeeder.class);

    private final ApplicationRoleRepository roles;
    private final ExerciseRepository exercises;

    public DbSeeder(ApplicationRoleRepository roles, ExerciseRepository exercises) {
        this.roles = roles;
        this.exercises = exercises;
    }

    @Transactional
    public void seed() {
        seedRoles();
        seedExercises();
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
}
