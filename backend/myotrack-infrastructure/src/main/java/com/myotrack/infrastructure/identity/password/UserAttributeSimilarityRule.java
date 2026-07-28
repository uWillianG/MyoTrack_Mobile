package com.myotrack.infrastructure.identity.password;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

/**
 * Recusa senhas parecidas demais com os dados da própria conta (e-mail e nome).
 * Quem usa "willian2024" com o e-mail willian@… entrega a senha junto com o
 * login em qualquer vazamento de e-mails.
 *
 * <p>Mesma regra do {@code UserAttributeSimilarityValidator} do Django: compara a senha com
 * cada atributo inteiro e com cada pedaço dele (separado por pontuação), usando a razão do
 * {@code SequenceMatcher.quick_ratio} do Python — 2 × (caracteres em comum, contados como
 * multiconjunto) ÷ (soma dos tamanhos).
 */
@Component
public class UserAttributeSimilarityRule implements PasswordRule {

    private static final double MAX_SIMILARITY = 0.7;
    private static final Pattern NON_WORD = Pattern.compile("\\W+");

    @Override
    public Optional<PasswordError> validate(String password, PasswordOwner owner) {
        if (password == null || password.isEmpty()) {
            return Optional.empty();
        }

        String lowered = password.toLowerCase(Locale.ROOT);

        for (Attribute attribute : List.of(
                new Attribute(owner.email(), "o seu e-mail"),
                new Attribute(owner.displayName(), "o seu nome"))) {

            if (attribute.value() == null || attribute.value().isBlank()) {
                continue;
            }

            String value = attribute.value().toLowerCase(Locale.ROOT);
            List<String> parts = new ArrayList<>(List.of(NON_WORD.split(value)));
            parts.add(value);

            for (String part : parts) {
                if (part.isEmpty() || skipByLength(lowered, part)) {
                    continue;
                }
                if (quickRatio(lowered, part) < MAX_SIMILARITY) {
                    continue;
                }
                return Optional.of(new PasswordError(
                        "PasswordTooSimilarToUser",
                        "A senha é muito parecida com %s.".formatted(attribute.label())));
            }
        }

        return Optional.empty();
    }

    /**
     * Pedaço curto demais para alcançar a similaridade máxima diante de uma
     * senha longa — não há como passar do limite, então nem calcula.
     */
    private static boolean skipByLength(String password, String value) {
        return password.length() >= 10 * value.length()
                && value.length() < MAX_SIMILARITY / 2 * password.length();
    }

    /**
     * Porta do {@code difflib.SequenceMatcher.quick_ratio}: trata as strings como
     * multiconjuntos de caracteres, então "abc123" e "321cba" batem 100%.
     */
    public static double quickRatio(String a, String b) {
        if (a.length() + b.length() == 0) {
            return 1.0;
        }

        Map<Character, Integer> available = new HashMap<>();
        for (char c : b.toCharArray()) {
            available.merge(c, 1, Integer::sum);
        }

        int matches = 0;
        for (char c : a.toCharArray()) {
            Integer remaining = available.get(c);
            if (remaining != null && remaining > 0) {
                available.put(c, remaining - 1);
                matches++;
            }
        }

        return 2.0 * matches / (a.length() + b.length());
    }

    private record Attribute(String value, String label) {
    }
}
