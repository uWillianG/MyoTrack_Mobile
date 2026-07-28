package com.myotrack.api.profile;

import com.myotrack.api.profile.ProfileDtos.ConsentRequest;
import com.myotrack.api.profile.ProfileDtos.ProfileRequest;
import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.entity.ConsentRecord;
import com.myotrack.domain.entity.UserProfile;
import com.myotrack.infrastructure.repository.ConsentRecordRepository;
import com.myotrack.infrastructure.repository.UserProfileRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Porte de MyoTrack.Api/Controllers/ProfileController.cs. */
@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final UserProfileRepository profiles;
    private final ConsentRecordRepository consents;

    public ProfileController(UserProfileRepository profiles, ConsentRecordRepository consents) {
        this.profiles = profiles;
        this.consents = consents;
    }

    /** 404 quando ainda não há perfil — é como o app sabe que precisa abrir o onboarding. */
    @GetMapping
    public ResponseEntity<UserProfile> get() {
        return profiles.findByUserId(CurrentUser.id())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping
    @Transactional
    public ResponseEntity<?> upsert(@RequestBody ProfileRequest request) {
        if (request.trainingDaysPerWeek() < 1 || request.trainingDaysPerWeek() > 7) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Dias de treino por semana deve estar entre 1 e 7."));
        }
        if (request.sex() != null && !request.sex().equals("M") && !request.sex().equals("F")) {
            return ResponseEntity.badRequest().body(Map.of("error", "Sexo deve ser 'M' ou 'F'."));
        }

        final UUID userId = CurrentUser.id();
        final UserProfile profile = profiles.findByUserId(userId).orElseGet(() -> {
            final UserProfile created = new UserProfile();
            created.setUserId(userId);
            return created;
        });

        profile.setBirthDate(request.birthDate());
        profile.setSex(request.sex());
        profile.setHeightCm(request.heightCm());
        profile.setBiotype(request.biotype());
        profile.setExperienceLevel(request.experienceLevel());
        profile.setGoal(request.goal());
        profile.setTrainingDaysPerWeek(request.trainingDaysPerWeek());
        // Listas nulas viram vazias: as colunas são NOT NULL e o motor de regras
        // trata "sem restrição" como lista vazia, não como null.
        profile.setPriorityMuscleGroups(orEmpty(request.priorityMuscleGroups()));
        profile.setInjuryNotes(request.injuryNotes());
        profile.setInjuryTags(toArray(request.injuryTags()));
        profile.setAvailableEquipment(orEmpty(request.availableEquipment()));
        profile.setDietaryRestrictions(toArray(request.dietaryRestrictions()));
        profile.setFoodPreferences(toArray(request.foodPreferences()));
        profile.setUpdatedAt(OffsetDateTime.now());

        return ResponseEntity.ok(profiles.save(profile));
    }

    /**
     * Registra os consentimentos (LGPD).
     *
     * <p>É uma trilha append-only: cada aceite vira uma linha nova com a versão dos termos, e
     * nada é sobrescrito. É isso que permite provar depois o que o titular aceitou e quando.
     */
    @PostMapping("/consents")
    @Transactional
    public ResponseEntity<Void> recordConsents(@RequestBody List<ConsentRequest> requests) {
        final UUID userId = CurrentUser.id();

        final List<ConsentRecord> records = requests.stream().map(request -> {
            final ConsentRecord record = new ConsentRecord();
            record.setUserId(userId);
            record.setType(request.type());
            record.setTermsVersion(request.termsVersion());
            return record;
        }).toList();

        consents.saveAll(records);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/consents")
    public List<ConsentRecord> getConsents() {
        return consents.findByUserIdOrderByGrantedAtDesc(CurrentUser.id());
    }

    private static <T> List<T> orEmpty(List<T> values) {
        return Optional.ofNullable(values).orElseGet(List::of);
    }

    private static String[] toArray(List<String> values) {
        return orEmpty(values).toArray(String[]::new);
    }
}
