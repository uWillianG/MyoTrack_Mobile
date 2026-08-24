package com.myotrack.api.billing;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Credenciais da App Store Server API — a chave com que o servidor pergunta à Apple o estado de
 * uma assinatura.
 *
 * <p>São quatro valores e todos vêm do App Store Connect: a chave privada (.p8) é baixada uma
 * única vez, e o {@code issuerId} e o {@code keyId} identificam quem a emitiu. O {@code bundleId}
 * entra no token e é conferido em todo dado assinado que chega — é o que impede um recibo
 * legítimo de <b>outro</b> app de virar Pro aqui dentro.
 *
 * <p>Faltando qualquer um, {@link #isConfigured()} é falso e o endpoint de compra responde 503.
 * Nunca o contrário: um ambiente sem credencial não concede o benefício, ele recusa a venda.
 */
@ConfigurationProperties(prefix = "myotrack.billing.apple")
public record AppStoreProperties(String issuerId, String keyId, String privateKey, String bundleId) {

    public AppStoreProperties {
        issuerId = blankToEmpty(issuerId);
        keyId = blankToEmpty(keyId);
        bundleId = blankToEmpty(bundleId);

        // A .p8 tem quebras de linha, e variável de ambiente não costuma sobreviver a elas: quem
        // exporta a chave quase sempre acaba com "\n" literal no meio do PEM. Normalizar aqui
        // evita o erro mais provável desta configuração, que apareceria lá adiante como uma
        // chave ilegível — mensagem que não ajuda ninguém a achar a causa.
        privateKey = blankToEmpty(privateKey).replace("\n", "\n");
    }

    public boolean isConfigured() {
        return !issuerId.isBlank() && !keyId.isBlank() && !privateKey.isBlank() && !bundleId.isBlank();
    }

    private static String blankToEmpty(String value) {
        return value == null || value.isBlank() ? "" : value;
    }
}
