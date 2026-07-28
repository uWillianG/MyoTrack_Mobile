package com.myotrack.infrastructure.identity.password;

import com.myotrack.infrastructure.identity.ApplicationUser;
import com.myotrack.infrastructure.identity.password.PasswordRule.PasswordOwner;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;

/**
 * Aplica todas as regras de senha, na mesma ordem do Program.cs do .NET: composição primeiro,
 * depois lista de vazadas e semelhança com os dados da conta.
 *
 * <p>Vale tanto no cadastro quanto na redefinição.
 */
@Service
public class PasswordPolicy {

    private final List<PasswordRule> rules;

    public PasswordPolicy(
            PasswordCompositionRule composition,
            CommonPasswordRule common,
            UserAttributeSimilarityRule similarity) {
        this.rules = List.of(composition, common, similarity);
    }

    /** Todas as falhas encontradas — a tela mostra a lista inteira, não só a primeira. */
    public List<PasswordError> validate(String password, PasswordOwner owner) {
        return rules.stream()
                .map(rule -> rule.validate(password, owner))
                .flatMap(Optional::stream)
                .toList();
    }

    public List<PasswordError> validate(String password, ApplicationUser user) {
        return validate(password, new PasswordOwner(user.getEmail(), user.getDisplayName()));
    }

    public List<PasswordError> validate(String password, String email, String displayName) {
        return validate(password, new PasswordOwner(email, displayName));
    }
}
