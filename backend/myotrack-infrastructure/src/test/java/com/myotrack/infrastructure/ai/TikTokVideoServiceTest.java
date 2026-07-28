package com.myotrack.infrastructure.ai;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** Porte de MyoTrack.Tests/TikTokVideoServiceTests.cs. */
class TikTokVideoServiceTest {

    @Test
    void extractFirstVideoUrlFromPlainHtml() {
        String html = """
                <a href="https://www.tiktok.com/@personal.fit/video/7301234567890123456">agachamento</a>
                <a href="https://www.tiktok.com/@outro/video/9999999999999999999">outro</a>
                """;

        assertThat(TikTokVideoService.extractFirstVideoUrl(html))
                .isEqualTo("https://www.tiktok.com/@personal.fit/video/7301234567890123456");
    }

    @Test
    @DisplayName("Reconhece a URL com as barras escapadas como \\u002F")
    void extractFirstVideoUrlFromJsonWithEscapedSlashes() {
        String html = "{\"shareUrl\":\"https:\\u002F\\u002Fwww.tiktok.com\\u002F@treino.certo"
                + "\\u002Fvideo\\u002F7311111111111111111\"}";

        assertThat(TikTokVideoService.extractFirstVideoUrl(html))
                .isEqualTo("https://www.tiktok.com/@treino.certo/video/7311111111111111111");
    }

    @Test
    @DisplayName("Reconhece a URL com as barras escapadas como \\/")
    void extractFirstVideoUrlFromJsonWithBackslashSlashes() {
        String html = "{\"url\":\"https:\\/\\/www.tiktok.com\\/@coach_br\\/video\\/7322222222222222222\"}";

        assertThat(TikTokVideoService.extractFirstVideoUrl(html))
                .isEqualTo("https://www.tiktok.com/@coach_br/video/7322222222222222222");
    }

    @Test
    @DisplayName("Sem vídeo no HTML devolve null — o cliente cai para a URL de busca")
    void extractFirstVideoUrlNoMatchReturnsNull() {
        assertThat(TikTokVideoService.extractFirstVideoUrl("<html><body>login required</body></html>"))
                .isNull();
        // /photo/ não é vídeo, e o YouTube não interessa aqui.
        assertThat(TikTokVideoService.extractFirstVideoUrl(
                "https://www.tiktok.com/@user/photo/123 https://www.youtube.com/watch?v=abc"))
                .isNull();
        assertThat(TikTokVideoService.extractFirstVideoUrl(null)).isNull();
        assertThat(TikTokVideoService.extractFirstVideoUrl("")).isNull();
    }

    @Test
    @DisplayName("A busca codifica acentos e espaços como %20, não como '+'")
    void buildSearchUrlEncodesExerciseName() {
        String url = TikTokVideoService.buildSearchUrl("Agachamento Búlgaro");

        assertThat(url).startsWith("https://www.tiktok.com/search?q=");
        assertThat(url).contains("como%20fazer%20Agachamento%20B%C3%BAlgaro%20academia");
        assertThat(url).doesNotContain("+");
    }
}
