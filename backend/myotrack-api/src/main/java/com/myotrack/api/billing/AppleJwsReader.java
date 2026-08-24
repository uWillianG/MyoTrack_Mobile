package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.Signature;
import java.security.cert.CertPath;
import java.security.cert.CertPathValidator;
import java.security.cert.CertificateFactory;
import java.security.cert.PKIXParameters;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.time.Clock;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Component;

/**
 * Verifica JWS da Apple pela cadeia de certificados que ele carrega.
 *
 * <p>Todo dado assinado da App Store — recibo de compra, transação dentro de uma notificação,
 * estado devolvido pela Server API — vem no mesmo formato: um JWS ES256 cujo cabeçalho traz a
 * cadeia inteira em {@code x5c}, do certificado que assinou até a raiz da Apple. Confiar nele é
 * conferir que essa cadeia sobe até a <b>nossa</b> cópia da raiz, e não até a que veio junto:
 * quem forja um JWS forja o {@code x5c} inteiro, e uma cadeia que valida contra si mesma valida
 * sempre.
 *
 * <p>A raiz vive em {@code resources/apple/AppleRootCA-G3.pem}, versionada com o código. Buscá-la
 * na rede a cada verificação criaria uma dependência de disponibilidade para cobrar — e um lugar
 * a mais para alguém interceptar.
 *
 * <p><b>Uma diferença conhecida em relação à biblioteca oficial da Apple:</b> ela também exige um
 * marcador (extensão OID) no certificado folha, garantindo que ele é de assinatura de recibo e
 * não outro certificado qualquer emitido pela mesma raiz. Aqui isso não é replicado — o que
 * fecha essa brecha é a conferência do {@code bundleId} do payload, feita por quem chama.
 */
@Component
public class AppleJwsReader implements AppleSignedData {

    static final String ROOT_CERTIFICATE = "/apple/AppleRootCA-G3.pem";

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** O único algoritmo que a Apple usa nestes JWS. Aceitar outro é aceitar {@code alg: none}. */
    private static final String ALGORITHM = "ES256";

    /**
     * ECDSA no formato cru (R||S) que o JOSE usa — o padrão do Java é DER, e verificar um com o
     * outro falha em toda assinatura válida. O JDK expõe os dois desde a 9.
     */
    private static final String SIGNATURE_ALGORITHM = "SHA256withECDSAinP1363Format";

    private final X509Certificate root;
    private final Clock clock;

    public AppleJwsReader(Clock clock) {
        this.clock = clock;
        this.root = loadRoot();
    }

    @Override
    public JsonNode read(String jws) {
        if (jws == null || jws.isBlank()) {
            throw new InvalidSignedDataException("Dado assinado ausente.");
        }

        final String[] parts = jws.split("\\.");
        if (parts.length != 3) {
            throw new InvalidSignedDataException("JWS malformado.");
        }

        final JsonNode header = decodePart(parts[0], "cabeçalho");
        if (!ALGORITHM.equals(header.path("alg").asText())) {
            throw new InvalidSignedDataException(
                    "Algoritmo inesperado: " + header.path("alg").asText());
        }

        final List<X509Certificate> chain = certificates(header);
        verifyChain(chain);
        verifySignature(parts, chain.getFirst());

        return decodePart(parts[1], "payload");
    }

    /** {@code x5c} vem do folha para a raiz, cada certificado em base64 padrão (DER). */
    private static List<X509Certificate> certificates(JsonNode header) {
        final JsonNode x5c = header.path("x5c");
        if (!x5c.isArray() || x5c.isEmpty()) {
            throw new InvalidSignedDataException("JWS sem cadeia de certificados.");
        }

        try {
            final CertificateFactory factory = CertificateFactory.getInstance("X.509");
            final List<X509Certificate> chain = new ArrayList<>(x5c.size());
            for (final JsonNode encoded : x5c) {
                final byte[] der = Base64.getDecoder().decode(encoded.asText());
                chain.add((X509Certificate)
                        factory.generateCertificate(new ByteArrayInputStream(der)));
            }
            return chain;
        } catch (Exception e) {
            throw new InvalidSignedDataException("Cadeia de certificados ilegível.", e);
        }
    }

    /**
     * Valida do folha até a raiz que temos aqui.
     *
     * <p>O último elemento do {@code x5c} é a própria raiz e é descartado: âncora de confiança é
     * a nossa cópia, e incluir a do JWS no caminho faria o validador exigir que a raiz tivesse
     * sido assinada por alguém.
     *
     * <p>Revogação fica desligada porque ligá-la significaria uma consulta OCSP à Apple no meio
     * de uma compra: com o OCSP fora do ar, a validação falharia e a venda cairia junto. A janela
     * que isso abre é a de um certificado intermediário revogado e ainda dentro da validade —
     * risco menor que o de depender de mais um serviço para cobrar.
     */
    private void verifyChain(List<X509Certificate> chain) {
        // Descarta o último só quando ele é mesmo a nossa raiz. Uma cadeia que termine em outra
        // coisa segue inteira para o validador — e é rejeitada por ele, que é o certo: cortar o
        // último elemento sem olhar transformaria uma cadeia estranha em uma mais curta.
        final List<X509Certificate> path = chain.size() > 1 && root.equals(chain.getLast())
                ? chain.subList(0, chain.size() - 1)
                : chain;

        try {
            final CertPath certPath =
                    CertificateFactory.getInstance("X.509").generateCertPath(path);

            final PKIXParameters parameters =
                    new PKIXParameters(Set.of(new TrustAnchor(root, null)));
            parameters.setRevocationEnabled(false);
            parameters.setDate(Date.from(clock.instant()));

            CertPathValidator.getInstance("PKIX").validate(certPath, parameters);
        } catch (Exception e) {
            throw new InvalidSignedDataException("Cadeia não sobe até a raiz da Apple.", e);
        }
    }

    /** A assinatura cobre {@code cabeçalho.payload} exatamente como vieram, ainda em base64url. */
    private static void verifySignature(String[] parts, X509Certificate leaf) {
        try {
            final Signature signature = Signature.getInstance(SIGNATURE_ALGORITHM);
            signature.initVerify(leaf.getPublicKey());
            signature.update((parts[0] + "." + parts[1]).getBytes(StandardCharsets.US_ASCII));

            if (!signature.verify(Base64.getUrlDecoder().decode(parts[2]))) {
                throw new InvalidSignedDataException("Assinatura não confere.");
            }
        } catch (InvalidSignedDataException e) {
            throw e;
        } catch (Exception e) {
            throw new InvalidSignedDataException("Não foi possível verificar a assinatura.", e);
        }
    }

    private static JsonNode decodePart(String part, String what) {
        try {
            return MAPPER.readTree(Base64.getUrlDecoder().decode(part));
        } catch (Exception e) {
            throw new InvalidSignedDataException("JWS com " + what + " ilegível.", e);
        }
    }

    private static X509Certificate loadRoot() {
        try (InputStream pem = AppleJwsReader.class.getResourceAsStream(ROOT_CERTIFICATE)) {
            if (pem == null) {
                throw new IllegalStateException("Certificado raiz da Apple ausente do jar.");
            }
            return (X509Certificate)
                    CertificateFactory.getInstance("X.509").generateCertificate(pem);
        } catch (Exception e) {
            // Sem raiz não há verificação possível, e seguir sem ela seria aceitar qualquer
            // assinatura: falhar na subida da API é a única saída honesta.
            throw new IllegalStateException("Não foi possível carregar a raiz da Apple.", e);
        }
    }
}
