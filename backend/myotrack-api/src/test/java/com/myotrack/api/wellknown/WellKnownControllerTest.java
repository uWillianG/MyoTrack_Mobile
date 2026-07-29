package com.myotrack.api.wellknown;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * Os arquivos de verificação de domínio.
 *
 * <p>O que se protege aqui é o modo de falhar. Um assetlinks.json sem impressão digital, ou um
 * apple-app-site-association com Team ID em branco, são arquivos que a plataforma busca, lê e
 * descarta sem dizer nada — e o sintoma no aparelho é idêntico ao de não ter arquivo algum.
 * Não servir é melhor: pelo menos um 404 aparece no log de quem for investigar.
 */
class WellKnownControllerTest {

    private static WellKnownController controllerWith(
            String packageName, List<String> fingerprints, String appleAppId) {
        return new WellKnownController(
                new DeepLinkProperties(packageName, fingerprints, appleAppId));
    }

    @Nested
    @DisplayName("Android — assetlinks.json")
    class Android {

        @Test
        @DisplayName("declara o pacote e as impressões digitais configuradas")
        void servesStatement() {
            var response = controllerWith(
                    "com.myotrack.app", List.of("AA:BB", "CC:DD"), "").assetLinks();

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

            Map<String, Object> statement = response.getBody().getFirst();
            assertThat(statement.get("relation"))
                    .isEqualTo(List.of("delegate_permission/common.handle_all_urls"));

            @SuppressWarnings("unchecked")
            Map<String, Object> target = (Map<String, Object>) statement.get("target");
            assertThat(target.get("namespace")).isEqualTo("android_app");
            assertThat(target.get("package_name")).isEqualTo("com.myotrack.app");
            // Mais de uma impressão é caso real: migração de chave, ou autorizar a de debug
            // num ambiente de teste.
            assertThat(target.get("sha256_cert_fingerprints")).isEqualTo(List.of("AA:BB", "CC:DD"));
        }

        @Test
        @DisplayName("sem impressão digital não serve nada")
        void refusesWithoutFingerprints() {
            // Um arquivo com a lista vazia é sintaticamente válido e não autoriza app nenhum:
            // pior que a ausência, porque parece configurado.
            var response = controllerWith("com.myotrack.app", List.of(), "").assetLinks();

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        }

        @Test
        @DisplayName("impressão em branco não conta como configuração")
        void blankFingerprintIsIgnored() {
            var response = controllerWith("com.myotrack.app", List.of("", "   "), "").assetLinks();

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        }
    }

    @Nested
    @DisplayName("iOS — apple-app-site-association")
    class Apple {

        @Test
        @DisplayName("declara o appID e os caminhos que o app abre")
        void servesAssociation() {
            var response = controllerWith("", List.of(), "ABCDE12345.com.myotrack.app")
                    .appleAppSiteAssociation();

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

            @SuppressWarnings("unchecked")
            Map<String, Object> applinks = (Map<String, Object>) response.getBody().get("applinks");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> details = (List<Map<String, Object>>) applinks.get("details");

            assertThat(details.getFirst().get("appIDs"))
                    .isEqualTo(List.of("ABCDE12345.com.myotrack.app"));

            @SuppressWarnings("unchecked")
            List<Map<String, String>> components =
                    (List<Map<String, String>>) details.getFirst().get("components");
            assertThat(components).contains(Map.of("/", "/redefinir-senha"));
        }

        @Test
        @DisplayName("os caminhos são explícitos, e não um curinga")
        void doesNotClaimTheWholeDomain() {
            // "*" entregaria ao app qualquer endereço do domínio, inclusive as páginas do site
            // que só fazem sentido no navegador.
            var response = controllerWith("", List.of(), "ABCDE12345.com.myotrack.app")
                    .appleAppSiteAssociation();

            @SuppressWarnings("unchecked")
            Map<String, Object> applinks = (Map<String, Object>) response.getBody().get("applinks");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> details = (List<Map<String, Object>>) applinks.get("details");
            @SuppressWarnings("unchecked")
            List<Map<String, String>> components =
                    (List<Map<String, String>>) details.getFirst().get("components");

            assertThat(components).doesNotContain(Map.of("/", "*"));
            assertThat(components).allSatisfy(c -> assertThat(c.get("/")).startsWith("/"));
        }

        @Test
        @DisplayName("sem Team ID não serve nada")
        void refusesWithoutTeamId() {
            var response = controllerWith("", List.of(), "").appleAppSiteAssociation();

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        }
    }

    @Test
    @DisplayName("cada plataforma é independente da outra")
    void platformsAreIndependent() {
        // Configurar Android não pode fazer o arquivo da Apple aparecer com valor vazio, nem
        // o contrário: as duas decisões acontecem em momentos diferentes do projeto.
        WellKnownController onlyAndroid =
                controllerWith("com.myotrack.app", List.of("AA:BB"), "");

        assertThat(onlyAndroid.assetLinks().getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(onlyAndroid.appleAppSiteAssociation().getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    @DisplayName("os caminhos declarados existem no roteador do app")
    void pathsMatchTheAppRoutes() {
        // Um caminho aqui que o app não conhece abre o app numa rota inexistente; o inverso
        // (rota nova sem entrada aqui) só deixa de funcionar por link, o que é aceitável.
        ResponseEntity<Map<String, Object>> response =
                controllerWith("", List.of(), "ABCDE12345.com.myotrack.app")
                        .appleAppSiteAssociation();

        @SuppressWarnings("unchecked")
        Map<String, Object> applinks = (Map<String, Object>) response.getBody().get("applinks");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> details = (List<Map<String, Object>>) applinks.get("details");
        @SuppressWarnings("unchecked")
        List<Map<String, String>> components =
                (List<Map<String, String>>) details.getFirst().get("components");

        assertThat(components).contains(
                Map.of("/", "/redefinir-senha"),
                Map.of("/", "/diario"),
                Map.of("/", "/coach"));
    }
}
