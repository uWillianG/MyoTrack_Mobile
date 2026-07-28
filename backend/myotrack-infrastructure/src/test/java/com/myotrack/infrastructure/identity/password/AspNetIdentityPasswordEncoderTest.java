package com.myotrack.infrastructure.identity.password;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * Os hashes abaixo foram gerados pelo {@code PasswordHasher<T>} real do ASP.NET Core 9
 * (pacote Microsoft.Extensions.Identity.Core 9.0.0) — não por este código. É essa procedência
 * que torna o teste uma prova de compatibilidade: se ele passar, um usuário cadastrado pelo
 * backend .NET consegue entrar pelo backend Java.
 *
 * <p>Todos vieram no formato V3 com PRF=2 (HMAC-SHA512), 100.000 iterações, salt de 16 B e
 * subkey de 32 B, que são os padrões desta versão do .NET.
 */
class AspNetIdentityPasswordEncoderTest {

    private final AspNetIdentityPasswordEncoder encoder =
            new AspNetIdentityPasswordEncoder("HMACSHA512", 100_000);

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
        "Tr0vao!Verde9   | AQAAAAIAAYagAAAAECvel98b9kF9AbS42EjaghYAZgW9wZSuOqzeuFtrZpjy+aFyHKNbNgk0pLNs9SCggg==",
        "Cachorro#Azul42 | AQAAAAIAAYagAAAAEH6k6/GUM1roWe5/202e+8deC85MWJEn6EPbuRg4X3ari7IAY6yTUXAGslcSD4a/ow==",
        "Senha@123       | AQAAAAIAAYagAAAAEKAqBLquz8ODCTs/CGLoEp6E2TfPPJk+Q+/lD9bzYRGt0ntJc1amHxj8e8rMjgOz4A=="
    })
    @DisplayName("Aceita hashes gravados pelo backend .NET")
    void matchesHashesProducedByDotNet(String password, String hash) {
        assertThat(encoder.matches(password.trim(), hash.trim())).isTrue();
    }

    @Test
    @DisplayName("Senha com acento casa — prova que a codificação dos chars é UTF-8 nos dois lados")
    void matchesNonAsciiPassword() {
        String hash = "AQAAAAIAAYagAAAAEItJKmVPSXkw4MM018GiDr7ArR45Ibif3JHGtJB/8hjaP1K9eFt2eSivgSsU5/bDbA==";
        assertThat(encoder.matches("áçêntõ!X9z", hash)).isTrue();
    }

    @Test
    void rejectsWrongPassword() {
        String hash = "AQAAAAIAAYagAAAAECvel98b9kF9AbS42EjaghYAZgW9wZSuOqzeuFtrZpjy+aFyHKNbNgk0pLNs9SCggg==";
        assertThat(encoder.matches("Tr0vao!Verde8", hash)).isFalse();
        assertThat(encoder.matches("", hash)).isFalse();
    }

    @Test
    @DisplayName("Conta sem senha (login com Google) não casa com senha nenhuma")
    void rejectsWhenHashIsMissing() {
        assertThat(encoder.matches("qualquer coisa", null)).isFalse();
        assertThat(encoder.matches("qualquer coisa", "")).isFalse();
    }

    @Test
    void rejectsMalformedHashInsteadOfThrowing() {
        assertThat(encoder.matches("Tr0vao!Verde9", "isto não é base64 %%%")).isFalse();
        // Base64 válido, mas marcador de formato desconhecido.
        assertThat(encoder.matches("Tr0vao!Verde9", "AgAAAAIAAYagAAAAEA==")).isFalse();
    }

    @Test
    @DisplayName("O hash gerado aqui tem o cabeçalho V3 esperado e é reversível")
    void encodeProducesV3AndRoundTrips() {
        String encoded = encoder.encode("Tr0vao!Verde9");

        byte[] decoded = java.util.Base64.getDecoder().decode(encoded);
        assertThat(decoded[0]).as("marcador V3").isEqualTo((byte) 0x01);
        assertThat(decoded).as("13 de cabeçalho + 16 de salt + 32 de subkey").hasSize(61);
        assertThat(readUInt32(decoded, 1)).as("PRF HMACSHA512").isEqualTo(2);
        assertThat(readUInt32(decoded, 5)).as("iterações").isEqualTo(100_000);
        assertThat(readUInt32(decoded, 9)).as("tamanho do salt").isEqualTo(16);

        assertThat(encoder.matches("Tr0vao!Verde9", encoded)).isTrue();
        assertThat(encoder.matches("outra senha", encoded)).isFalse();
    }

    @Test
    @DisplayName("Salt aleatório: a mesma senha nunca gera o mesmo hash")
    void encodeUsesRandomSalt() {
        assertThat(encoder.encode("Tr0vao!Verde9")).isNotEqualTo(encoder.encode("Tr0vao!Verde9"));
    }

    @Test
    @DisplayName("Hash V2 legado (PBKDF2-HMAC-SHA1, 1000 iterações) ainda é verificado")
    void matchesLegacyV2Hash() {
        // Montado com os parâmetros fixos do formato V2 do Identity.
        String v2Hash = buildV2Hash("Tr0vao!Verde9");
        assertThat(encoder.matches("Tr0vao!Verde9", v2Hash)).isTrue();
        assertThat(encoder.matches("Tr0vao!Verde8", v2Hash)).isFalse();
        // E é sinalizado para re-gravação no próximo login.
        assertThat(encoder.upgradeEncoding(v2Hash)).isTrue();
    }

    @Test
    void upgradeEncodingFlagsWeakerIterationCounts() {
        // 10.000 iterações era o padrão do ASP.NET Core 5 e anteriores.
        AspNetIdentityPasswordEncoder legacy = new AspNetIdentityPasswordEncoder("HMACSHA256", 10_000);
        assertThat(encoder.upgradeEncoding(legacy.encode("Tr0vao!Verde9"))).isTrue();
        assertThat(encoder.upgradeEncoding(encoder.encode("Tr0vao!Verde9"))).isFalse();
    }

    @Test
    @DisplayName("Verifica hash V3 com PRF diferente do padrão, lendo os parâmetros embutidos")
    void matchesHashWithDifferentPrf() {
        AspNetIdentityPasswordEncoder sha256 = new AspNetIdentityPasswordEncoder("HMACSHA256", 10_000);
        String hash = sha256.encode("Tr0vao!Verde9");

        // O encoder padrão (SHA512/100k) verifica mesmo assim: os parâmetros vêm do hash.
        assertThat(encoder.matches("Tr0vao!Verde9", hash)).isTrue();
    }

    private static String buildV2Hash(String password) {
        byte[] salt = new byte[16];
        for (int i = 0; i < salt.length; i++) {
            salt[i] = (byte) (i * 7 + 1);
        }
        byte[] subkey = pbkdf2(password, salt, 1000, 32);

        byte[] output = new byte[1 + salt.length + subkey.length];
        output[0] = 0x00;
        System.arraycopy(salt, 0, output, 1, salt.length);
        System.arraycopy(subkey, 0, output, 1 + salt.length, subkey.length);
        return java.util.Base64.getEncoder().encodeToString(output);
    }

    private static byte[] pbkdf2(String password, byte[] salt, int iterations, int lengthBytes) {
        try {
            javax.crypto.spec.PBEKeySpec spec = new javax.crypto.spec.PBEKeySpec(
                    password.toCharArray(), salt, iterations, lengthBytes * 8);
            return javax.crypto.SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1")
                    .generateSecret(spec).getEncoded();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static int readUInt32(byte[] buffer, int offset) {
        return java.nio.ByteBuffer.wrap(buffer, offset, 4).getInt();
    }
}
