package com.myotrack.infrastructure.identity;

import java.util.List;

/** Papéis semeados no startup. Espelha MyoTrack.Infrastructure.Identity.AppRoles. */
public final class AppRoles {

    public static final String STUDENT = "Student";
    public static final String TRAINER = "Trainer";
    public static final String NUTRITIONIST = "Nutritionist";
    public static final String ADMIN = "Admin";

    public static final List<String> ALL = List.of(STUDENT, TRAINER, NUTRITIONIST, ADMIN);

    private AppRoles() {
    }
}
