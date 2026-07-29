package com.myotrack.api.wellknown;

import java.util.List;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Verificação de domínio dos deep links: os arquivos que o Android e o iOS buscam para
 * confirmar que este domínio e o app são do mesmo dono.
 *
 * <p>Servidos pela API, e não como arquivo estático, por dois motivos. O
 * {@code apple-app-site-association} não tem extensão, e o servidor de estáticos do Spring o
 * entregaria como {@code application/octet-stream} — a Apple exige {@code application/json} e
 * descarta o resto sem dizer por quê. E o conteúdo é a identidade do app (pacote, impressões
 * digitais, Team ID), que vive neste repositório: mantê-lo aqui é o que impede o arquivo
 * publicado de divergir do app que ele descreve.
 *
 * <p>Os dois caminhos são públicos: quem os busca é o sistema operacional, antes de qualquer
 * login, às vezes na instalação do app.
 *
 * <p>Requisitos que não dependem deste código e falham em silêncio se faltarem: HTTPS válido,
 * <b>sem redirecionamento</b> (as duas plataformas recusam 301/302), e o caminho exato
 * {@code /.well-known/...} no domínio dos links.
 */
@RestController
public class WellKnownController {

    private final DeepLinkProperties properties;

    public WellKnownController(DeepLinkProperties properties) {
        this.properties = properties;
    }

    /**
     * Android App Links — {@code /.well-known/assetlinks.json}.
     *
     * <p>Com Play App Signing, a impressão digital que vale é a do <b>Google</b>, não a do
     * keystore de upload: o Google reassina o APK antes de distribuir. Ela está no Play
     * Console em Setup &gt; App signing. Pôr a de upload aqui é o engano comum, e o sintoma é
     * o link continuar abrindo o navegador sem nenhum erro visível.
     *
     * <p>A lista aceita mais de uma impressão de propósito: durante uma migração de chave, ou
     * para autorizar também a de debug em um ambiente de teste.
     */
    @GetMapping(value = "/.well-known/assetlinks.json", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<Map<String, Object>>> assetLinks() {
        if (!properties.isAndroidConfigured()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(List.of(Map.of(
                "relation", List.of("delegate_permission/common.handle_all_urls"),
                "target", Map.of(
                        "namespace", "android_app",
                        "package_name", properties.androidPackageName(),
                        "sha256_cert_fingerprints", properties.androidCertFingerprints()))));
    }

    /**
     * iOS Universal Links — {@code /.well-known/apple-app-site-association}.
     *
     * <p>Sem extensão no caminho: é assim que o iOS o procura.
     *
     * <p>O {@code appID} é {@code TEAMID.bundleId}. Os caminhos declarados aqui limitam o que
     * o app intercepta — {@code *} entregaria ao app qualquer endereço do domínio, inclusive
     * os do site que só fazem sentido no navegador.
     */
    @GetMapping(
            value = "/.well-known/apple-app-site-association",
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> appleAppSiteAssociation() {
        if (!properties.isAppleConfigured()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(Map.of(
                "applinks", Map.of(
                        "details", List.of(Map.of(
                                "appIDs", List.of(properties.appleAppId()),
                                "components", DEEP_LINK_PATHS.stream()
                                        .map(path -> Map.of("/", path))
                                        .toList())))));
    }

    /**
     * Os caminhos que o app abre, espelhando as rotas de {@code app/lib/core/router.dart}.
     *
     * <p>Só entram os que fazem sentido vindos de fora: o link de redefinição, que chega por
     * e-mail, e as telas para as quais vale compartilhar um endereço. Uma rota nova só precisa
     * aparecer aqui se alguém for chegar nela por um link.
     */
    private static final List<String> DEEP_LINK_PATHS = List.of(
            "/redefinir-senha",
            "/redefinir-senha/*",
            "/esqueci-a-senha",
            "/treino",
            "/dieta",
            "/diario",
            "/refeicoes",
            "/videos",
            "/coach",
            "/assinatura",
            "/conta");
}
