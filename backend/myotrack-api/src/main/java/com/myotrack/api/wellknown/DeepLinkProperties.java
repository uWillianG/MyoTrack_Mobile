package com.myotrack.api.wellknown;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Identidade do app para a verificação de domínio dos deep links.
 *
 * <p>São os dados que provam ao Android e ao iOS que este domínio e aquele app pertencem ao
 * mesmo dono. Sem eles o link {@code https://myotrack.app/redefinir-senha?...} que o backend
 * manda por e-mail abre o navegador em vez do app.
 *
 * <p>Tudo vazio por padrão, e é de propósito. Os dois valores só existem depois de decisões
 * que não são deste repositório — publicar na Play Store e ter conta paga da Apple —, e
 * inventar um deles não deixaria os links "quase funcionando": produziria um arquivo que a
 * plataforma busca, lê e rejeita, com o app se comportando como se nada tivesse sido
 * configurado. Melhor não publicar o arquivo do que publicar um errado.
 */
@ConfigurationProperties(prefix = "myotrack.deep-links")
public record DeepLinkProperties(
        String androidPackageName,
        List<String> androidCertFingerprints,
        String appleAppId) {

    public DeepLinkProperties {
        androidPackageName = androidPackageName == null ? "" : androidPackageName.trim();
        appleAppId = appleAppId == null ? "" : appleAppId.trim();
        androidCertFingerprints = androidCertFingerprints == null
                ? List.of()
                : androidCertFingerprints.stream()
                        .filter(f -> f != null && !f.isBlank())
                        .map(String::trim)
                        .toList();
    }

    /**
     * O assetlinks.json só faz sentido com pelo menos uma impressão digital.
     *
     * <p>Uma lista vazia geraria um arquivo sintaticamente válido que não autoriza app nenhum
     * — pior que a ausência do arquivo, porque parece configurado.
     */
    public boolean isAndroidConfigured() {
        return !androidPackageName.isBlank() && !androidCertFingerprints.isEmpty();
    }

    /** O app id da Apple é {@code TEAMID.bundleId} — sem o Team ID não há o que servir. */
    public boolean isAppleConfigured() {
        return !appleAppId.isBlank();
    }
}
