package com.myotrack.infrastructure.identity.password;

import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Verifica e gera hashes no formato do {@code PasswordHasher} do ASP.NET Core Identity.
 *
 * <p><b>Por que isto existe:</b> a coluna {@code AspNetUsers.PasswordHash} já está cheia de hashes
 * gravados pelo backend .NET. Um {@code BCryptPasswordEncoder} qualquer não os reconheceria e
 * <i>todos os usuários existentes perderiam o login</i>. Enquanto os dois backends convivem, os
 * hashes também precisam continuar legíveis pelo .NET — por isso a geração usa o mesmo formato,
 * não só a verificação.
 *
 * <h2>Formato V3</h2>
 * <pre>
 * byte  0        : marcador 0x01
 * bytes 1..4     : PRF   (uint32 big-endian) 0=HMACSHA1, 1=HMACSHA256, 2=HMACSHA512
 * bytes 5..8     : iterações (uint32 big-endian)
 * bytes 9..12    : tamanho do salt em bytes (uint32 big-endian)
 * bytes 13..     : salt, seguido da subkey derivada
 * </pre>
 * Tudo isso em Base64. Como os parâmetros viajam dentro do próprio hash, a verificação funciona
 * para qualquer combinação de PRF/iterações já gravada — inclusive as de versões antigas do .NET.
 *
 * <h2>Formato V2 (legado)</h2>
 * Marcador {@code 0x00}, PBKDF2-HMAC-SHA1, 1000 iterações, salt de 16 bytes e subkey de 32.
 * Aceito na verificação porque contas muito antigas podem tê-lo; nunca é gerado.
 */
@Component
public class AspNetIdentityPasswordEncoder implements PasswordEncoder {

    private static final Logger log = LoggerFactory.getLogger(AspNetIdentityPasswordEncoder.class);

    private static final byte FORMAT_MARKER_V2 = 0x00;
    private static final byte FORMAT_MARKER_V3 = 0x01;

    private static final int SALT_SIZE_BYTES = 128 / 8;
    private static final int SUBKEY_SIZE_BYTES = 256 / 8;

    private static final int V2_LENGTH = 1 + SALT_SIZE_BYTES + SUBKEY_SIZE_BYTES;
    private static final int V3_HEADER_LENGTH = 13;

    private final SecureRandom random = new SecureRandom();

    private final Prf prf;
    private final int iterations;

    /**
     * Padrões iguais aos do .NET 8/9 ({@code PasswordHasher} com {@code CompatibilityMode.V3}):
     * HMAC-SHA512 e 100.000 iterações. Configuráveis porque instalações que nasceram em versões
     * anteriores do .NET podem ter outro par — e, se o valor divergir, só muda o custo dos hashes
     * NOVOS; os antigos continuam sendo verificados pelos parâmetros embutidos neles.
     */
    public AspNetIdentityPasswordEncoder(
            @Value("${myotrack.security.password-hash.prf:HMACSHA512}") String prf,
            @Value("${myotrack.security.password-hash.iterations:100000}") int iterations) {
        this.prf = Prf.valueOf(prf);
        this.iterations = iterations;
    }

    @Override
    public String encode(CharSequence rawPassword) {
        byte[] salt = new byte[SALT_SIZE_BYTES];
        random.nextBytes(salt);
        byte[] subkey = deriveKey(rawPassword.toString(), salt, prf, iterations, SUBKEY_SIZE_BYTES);

        byte[] output = new byte[V3_HEADER_LENGTH + salt.length + subkey.length];
        output[0] = FORMAT_MARKER_V3;
        writeUInt32BigEndian(output, 1, prf.code);
        writeUInt32BigEndian(output, 5, iterations);
        writeUInt32BigEndian(output, 9, salt.length);
        System.arraycopy(salt, 0, output, V3_HEADER_LENGTH, salt.length);
        System.arraycopy(subkey, 0, output, V3_HEADER_LENGTH + salt.length, subkey.length);

        return Base64.getEncoder().encodeToString(output);
    }

    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {
        // Conta criada pelo login com Google não tem senha — nunca casa com senha nenhuma.
        if (rawPassword == null || encodedPassword == null || encodedPassword.isBlank()) {
            return false;
        }

        byte[] decoded;
        try {
            decoded = Base64.getDecoder().decode(encodedPassword);
        } catch (IllegalArgumentException e) {
            log.warn("PasswordHash não é Base64 válido; tratando como senha incorreta.");
            return false;
        }

        if (decoded.length == 0) {
            return false;
        }

        return switch (decoded[0]) {
            case FORMAT_MARKER_V2 -> verifyV2(rawPassword.toString(), decoded);
            case FORMAT_MARKER_V3 -> verifyV3(rawPassword.toString(), decoded);
            default -> {
                log.warn("Marcador de formato desconhecido (0x{}) no PasswordHash.",
                        Integer.toHexString(decoded[0] & 0xFF));
                yield false;
            }
        };
    }

    /**
     * O Spring chama isto para decidir se re-grava o hash no próximo login bem-sucedido.
     * Vale a pena quando a conta ainda está no V2 ou abaixo do custo atual.
     */
    @Override
    public boolean upgradeEncoding(String encodedPassword) {
        if (encodedPassword == null || encodedPassword.isBlank()) {
            return false;
        }
        try {
            byte[] decoded = Base64.getDecoder().decode(encodedPassword);
            if (decoded.length == 0 || decoded[0] == FORMAT_MARKER_V2) {
                return true;
            }
            if (decoded[0] != FORMAT_MARKER_V3 || decoded.length < V3_HEADER_LENGTH) {
                return false;
            }
            return readUInt32BigEndian(decoded, 5) < iterations;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private boolean verifyV2(String rawPassword, byte[] decoded) {
        if (decoded.length != V2_LENGTH) {
            return false;
        }
        byte[] salt = new byte[SALT_SIZE_BYTES];
        System.arraycopy(decoded, 1, salt, 0, salt.length);

        byte[] expected = new byte[SUBKEY_SIZE_BYTES];
        System.arraycopy(decoded, 1 + salt.length, expected, 0, expected.length);

        byte[] actual = deriveKey(rawPassword, salt, Prf.HMACSHA1, 1000, SUBKEY_SIZE_BYTES);
        return MessageDigest.isEqual(expected, actual);
    }

    private boolean verifyV3(String rawPassword, byte[] decoded) {
        if (decoded.length < V3_HEADER_LENGTH) {
            return false;
        }

        int prfCode = readUInt32BigEndian(decoded, 1);
        int iterationCount = readUInt32BigEndian(decoded, 5);
        int saltLength = readUInt32BigEndian(decoded, 9);

        // Um salt curto demais indicaria hash corrompido; o subkey precisa sobrar pelo menos 1 byte.
        if (saltLength < SALT_SIZE_BYTES || iterationCount < 1) {
            return false;
        }
        int subkeyLength = decoded.length - V3_HEADER_LENGTH - saltLength;
        if (subkeyLength < 1) {
            return false;
        }

        Prf storedPrf = Prf.fromCode(prfCode);
        if (storedPrf == null) {
            log.warn("PRF desconhecido ({}) no PasswordHash.", prfCode);
            return false;
        }

        byte[] salt = new byte[saltLength];
        System.arraycopy(decoded, V3_HEADER_LENGTH, salt, 0, saltLength);

        byte[] expected = new byte[subkeyLength];
        System.arraycopy(decoded, V3_HEADER_LENGTH + saltLength, expected, 0, subkeyLength);

        byte[] actual = deriveKey(rawPassword, salt, storedPrf, iterationCount, subkeyLength);
        return MessageDigest.isEqual(expected, actual);
    }

    private static byte[] deriveKey(String password, byte[] salt, Prf prf, int iterations, int keyLengthBytes) {
        try {
            // O SunJCE codifica os chars em UTF-8, igual ao .NET — senhas com acento batem.
            PBEKeySpec spec = new PBEKeySpec(
                    password.toCharArray(), salt, iterations, keyLengthBytes * 8);
            return SecretKeyFactory.getInstance(prf.algorithm).generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new IllegalStateException("Falha ao derivar a chave PBKDF2 (%s).".formatted(prf.algorithm), e);
        }
    }

    private static void writeUInt32BigEndian(byte[] buffer, int offset, int value) {
        ByteBuffer.wrap(buffer, offset, 4).putInt(value);
    }

    private static int readUInt32BigEndian(byte[] buffer, int offset) {
        return ByteBuffer.wrap(buffer, offset, 4).getInt();
    }

    /** Os códigos são os do enum {@code KeyDerivationPrf} do ASP.NET Core. */
    private enum Prf {
        HMACSHA1(0, "PBKDF2WithHmacSHA1"),
        HMACSHA256(1, "PBKDF2WithHmacSHA256"),
        HMACSHA512(2, "PBKDF2WithHmacSHA512");

        private final int code;
        private final String algorithm;

        Prf(int code, String algorithm) {
            this.code = code;
            this.algorithm = algorithm;
        }

        static Prf fromCode(int code) {
            for (Prf candidate : values()) {
                if (candidate.code == code) {
                    return candidate;
                }
            }
            return null;
        }
    }
}
