package com.myotrack.infrastructure.identity.password;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.zip.GZIPInputStream;
import org.springframework.stereotype.Component;

/**
 * Recusa senhas da lista das ~20 mil mais usadas em vazamentos. As regras de
 * composição (maiúscula, número, símbolo) não pegam "Senha@123": é justamente
 * esse tipo de senha que os ataques de dicionário tentam primeiro.
 *
 * <p>A lista vem do Django ({@code django/contrib/auth/common-passwords.txt.gz},
 * licença BSD-3), compilada por Royce Williams a partir de vazamentos públicos.
 * O arquivo é o mesmo byte a byte do backend .NET.
 */
@Component
public class CommonPasswordRule implements PasswordRule {

    private static final String RESOURCE = "/identity/common-passwords.txt.gz";

    /**
     * Complemento em pt-BR: a lista do Django é majoritariamente anglófona e
     * deixa passar senhas óbvias para o público daqui (times, "senha1234") e
     * para o contexto do produto ("treino", "supino").
     */
    private static final List<String> BRAZILIAN_EXTRAS = List.of(
            "futebol", "corinthians", "vasco", "cruzeiro", "botafogo", "internacional", "fluminense",
            "brasil123", "senha1234", "senha12345", "mudar123", "joao", "deus", "meuamor", "familia123",
            "saudade", "obrigado", "naosei", "naosei123", "dinheiro", "liberdade",
            "treino", "musculacao", "halteres", "supino", "agachamento", "malhar");

    // ~20 mil entradas: carregadas uma vez, na primeira instância.
    private final Set<String> passwords = load();

    @Override
    public Optional<PasswordError> validate(String password, PasswordOwner owner) {
        if (password == null) {
            return Optional.empty();
        }
        // Comparação em minúsculas e sem espaços nas pontas, como no Django.
        if (passwords.contains(password.trim().toLowerCase(Locale.ROOT))) {
            return Optional.of(new PasswordError(
                    "PasswordTooCommon", "Essa senha é muito comum — escolha outra, menos previsível."));
        }
        return Optional.empty();
    }

    private static Set<String> load() {
        Set<String> set = new HashSet<>(BRAZILIAN_EXTRAS);

        try (InputStream stream = CommonPasswordRule.class.getResourceAsStream(RESOURCE)) {
            if (stream == null) {
                throw new IllegalStateException("Recurso '%s' não encontrado.".formatted(RESOURCE));
            }
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(new GZIPInputStream(stream), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String entry = line.trim();
                    if (!entry.isEmpty()) {
                        set.add(entry);
                    }
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException("Falha ao carregar a lista de senhas vazadas.", e);
        }

        return Set.copyOf(set);
    }
}
