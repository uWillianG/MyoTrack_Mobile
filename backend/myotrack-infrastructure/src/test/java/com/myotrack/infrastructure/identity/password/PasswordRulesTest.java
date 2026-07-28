package com.myotrack.infrastructure.identity.password;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.myotrack.infrastructure.identity.password.PasswordRule.PasswordOwner;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Porte de MyoTrack.Tests/PasswordValidatorTests.cs. */
class PasswordRulesTest {

    @Nested
    class CommonPasswords {

        private final CommonPasswordRule rule = new CommonPasswordRule();

        private Optional<PasswordError> validate(String password) {
            return rule.validate(password, PasswordOwner.ANONYMOUS);
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "password", "123456789", "qwerty", "senha123",
            // A lista é comparada em minúsculas e sem espaços nas pontas, como no Django.
            "PassWord", "  password  "
        })
        void rejectsPasswordsFromTheLeakedList(String password) {
            assertThat(validate(password)).isPresent();
        }

        @ParameterizedTest
        @ValueSource(strings = { "futebol", "corinthians", "senha1234", "supino" })
        @DisplayName("Recusa senhas comuns no Brasil, ausentes da lista anglófona do Django")
        void rejectsBrazilianCommonPasswords(String password) {
            assertThat(validate(password)).isPresent();
        }

        @ParameterizedTest
        @ValueSource(strings = { "Tr0vao!Verde9", "Cachorro#Azul42" })
        void acceptsPasswordsOutsideTheList(String password) {
            assertThat(validate(password)).isEmpty();
        }

        @Test
        void rejectionExplainsTheReason() {
            PasswordError error = validate("password").orElseThrow();
            assertThat(error.code()).isEqualTo("PasswordTooCommon");
            assertThat(error.description()).contains("comum");
        }
    }

    @Nested
    class UserAttributeSimilarity {

        private final UserAttributeSimilarityRule rule = new UserAttributeSimilarityRule();

        private Optional<PasswordError> validate(String password, String email, String displayName) {
            return rule.validate(password, new PasswordOwner(email, displayName));
        }

        // Valores conferidos contra o difflib.SequenceMatcher.quick_ratio do Python,
        // que é a referência usada pelo validador equivalente do Django.
        @ParameterizedTest
        @CsvSource({
            "willian2024, willian, 0.777778",
            "gmail123, gmail, 0.769231",
            "'tr0vao!verde9', willian, 0.100000",
            "joaosilva, joao, 0.615385",
            // Multiconjunto de caracteres: a ordem não conta.
            "abc123, 321cba, 1.000000",
            "x, abcdefghij, 0.000000"
        })
        void quickRatioMatchesPythonDifflib(String a, String b, double expected) {
            assertThat(UserAttributeSimilarityRule.quickRatio(a, b)).isCloseTo(expected, within(1e-6));
        }

        @Test
        void quickRatioOfTwoEmptyStringsIsOne() {
            assertThat(UserAttributeSimilarityRule.quickRatio("", "")).isEqualTo(1.0);
        }

        @Test
        void rejectsPasswordBuiltFromTheEmailLocalPart() {
            PasswordError error = validate("Willian2024!", "willian@gmail.com", null).orElseThrow();
            assertThat(error.code()).isEqualTo("PasswordTooSimilarToUser");
            assertThat(error.description()).contains("e-mail");
        }

        @Test
        void rejectsPasswordBuiltFromTheDisplayName() {
            PasswordError error = validate("Cardoso#12", null, "Cardoso").orElseThrow();
            assertThat(error.description()).contains("nome");
        }

        @Test
        void acceptsPasswordUnrelatedToTheAccount() {
            assertThat(validate("Tr0vao!Verde9", "willian@gmail.com", "Willian")).isEmpty();
        }

        @Test
        void ignoresAccountsWithoutEmailOrName() {
            assertThat(validate("Tr0vao!Verde9", null, null)).isEmpty();
        }
    }

    @Nested
    class Composition {

        private final PasswordCompositionRule rule = new PasswordCompositionRule();

        private Optional<PasswordError> validate(String password) {
            return rule.validate(password, PasswordOwner.ANONYMOUS);
        }

        @ParameterizedTest
        @CsvSource({
            "'Ab1!def', PasswordTooShort",
            "'abcdef1!', PasswordRequiresUpper",
            "'ABCDEF1!', PasswordRequiresLower",
            "'Abcdefg!', PasswordRequiresDigit",
            "'Abcdefg1', PasswordRequiresNonAlphanumeric"
        })
        void rejectsWithTheRightCode(String password, String expectedCode) {
            assertThat(validate(password).orElseThrow().code()).isEqualTo(expectedCode);
        }

        @Test
        void acceptsAWellFormedPassword() {
            assertThat(validate("Tr0vao!Verde9")).isEmpty();
        }
    }

    @Nested
    class Policy {

        private final PasswordPolicy policy = new PasswordPolicy(
                new PasswordCompositionRule(), new CommonPasswordRule(), new UserAttributeSimilarityRule());

        @Test
        @DisplayName("Senha que passa na composição mas está na lista de vazadas é recusada")
        void catchesWhatCompositionAloneWouldLetThrough() {
            // "N0=acc3ss" tem 9 caracteres, maiúscula, minúscula, número e símbolo — passa em
            // todas as regras de composição — e mesmo assim está na lista de senhas vazadas.
            // É exatamente o buraco que esta regra existe para tapar.
            assertThat(new PasswordCompositionRule().validate("N0=acc3ss", PasswordOwner.ANONYMOUS)).isEmpty();

            assertThat(policy.validate("N0=acc3ss", "outro@exemplo.com", "Fulano"))
                    .extracting(PasswordError::code)
                    .containsExactly("PasswordTooCommon");
        }

        @Test
        void reportsEveryFailureAtOnce() {
            assertThat(policy.validate("iloveyou!", "iloveyou@gmail.com", "Fulano"))
                    .extracting(PasswordError::code)
                    .containsExactly("PasswordRequiresUpper", "PasswordTooCommon", "PasswordTooSimilarToUser");
        }

        @Test
        void acceptsAStrongUnrelatedPassword() {
            assertThat(policy.validate("Tr0vao!Verde9", "willian@gmail.com", "Willian")).isEmpty();
        }
    }
}
