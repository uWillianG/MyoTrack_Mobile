package com.myotrack.infrastructure.identity.password;

import java.util.Optional;

/**
 * Uma regra de senha. Equivale ao {@code IPasswordValidator<ApplicationUser>} do Identity,
 * mas sem depender do {@code UserManager} — as regras só precisam da senha e dos dados da conta.
 */
public interface PasswordRule {

    /** Vazio quando a senha passa; caso contrário, o motivo da recusa. */
    Optional<PasswordError> validate(String password, PasswordOwner owner);

    /** Dados da conta relevantes para as regras (o e-mail e o nome do titular). */
    record PasswordOwner(String email, String displayName) {

        public static final PasswordOwner ANONYMOUS = new PasswordOwner(null, null);
    }
}
