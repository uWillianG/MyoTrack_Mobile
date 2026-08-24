package com.myotrack.api.billing;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.myotrack.api.billing.AppleSignedData.InvalidSignedDataException;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.util.Base64;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * As recusas do leitor de JWS da Apple.
 *
 * <p>Não há aqui um JWS válido, e não pode haver: produzir um exigiria a chave da Apple. O que
 * se testa é o outro lado — que nada passa sem cadeia verificada. O primeiro teste parece bobo e
 * é o mais útil dos quatro: ele falha no build no dia em que o certificado raiz sair do jar, em
 * vez de a API subir e recusar toda compra em produção.
 */
class AppleJwsReaderTest {

    private static AppleJwsReader reader() {
        return new AppleJwsReader(Clock.systemUTC());
    }

    private static String jws(String header) {
        final String encoded = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(header.getBytes(StandardCharsets.UTF_8));
        return encoded + "." + encoded + ".assinatura";
    }

    @Test
    @DisplayName("a raiz da Apple está no jar e é legível")
    void carregaRaiz() {
        assertThatCode(AppleJwsReaderTest::reader).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("o que não tem três partes não é JWS")
    void recusaMalformado() {
        assertThatThrownBy(() -> reader().read("isto-nao-e-um-jws"))
                .isInstanceOf(InvalidSignedDataException.class);
    }

    @Test
    @DisplayName("algoritmo diferente do da Apple é recusado antes de qualquer outra coisa")
    void recusaOutroAlgoritmo() {
        // A recusa mais importante da classe: 'none' é a assinatura que qualquer um produz.
        assertThatThrownBy(() -> reader().read(jws("{\"alg\":\"none\"}")))
                .isInstanceOf(InvalidSignedDataException.class)
                .hasMessageContaining("none");
    }

    @Test
    @DisplayName("sem cadeia de certificados não há o que verificar")
    void recusaSemCadeia() {
        assertThatThrownBy(() -> reader().read(jws("{\"alg\":\"ES256\"}")))
                .isInstanceOf(InvalidSignedDataException.class)
                .hasMessageContaining("cadeia");
    }
}
