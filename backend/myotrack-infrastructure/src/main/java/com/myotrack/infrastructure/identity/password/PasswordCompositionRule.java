package com.myotrack.infrastructure.identity.password;

import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Regras de composição: mínimo de 8 caracteres com maiúscula, minúscula, número e símbolo.
 * Porte das {@code options.Password.*} do Program.cs, com as mensagens do
 * PortugueseIdentityErrorDescriber.
 *
 * <p>Composição sozinha não basta — "Senha@123" passa aqui e está em todo dicionário de ataque.
 * É o que as outras duas regras cobrem.
 */
@Component
public class PasswordCompositionRule implements PasswordRule {

    public static final int MIN_LENGTH = 8;

    @Override
    public Optional<PasswordError> validate(String password, PasswordOwner owner) {
        if (password == null || password.length() < MIN_LENGTH) {
            return Optional.of(new PasswordError(
                    "PasswordTooShort",
                    "A senha precisa ter pelo menos %d caracteres.".formatted(MIN_LENGTH)));
        }
        if (password.chars().noneMatch(Character::isUpperCase)) {
            return Optional.of(new PasswordError(
                    "PasswordRequiresUpper", "A senha precisa ter pelo menos uma letra maiúscula."));
        }
        if (password.chars().noneMatch(Character::isLowerCase)) {
            return Optional.of(new PasswordError(
                    "PasswordRequiresLower", "A senha precisa ter pelo menos uma letra minúscula."));
        }
        if (password.chars().noneMatch(Character::isDigit)) {
            return Optional.of(new PasswordError(
                    "PasswordRequiresDigit", "A senha precisa ter pelo menos um número."));
        }
        if (password.chars().allMatch(Character::isLetterOrDigit)) {
            return Optional.of(new PasswordError(
                    "PasswordRequiresNonAlphanumeric",
                    "A senha precisa ter pelo menos um símbolo (ex.: !, @, #)."));
        }
        return Optional.empty();
    }
}
