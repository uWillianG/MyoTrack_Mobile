package com.myotrack.worker;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.entity.ExerciseVideoAnalysis;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.infrastructure.repository.ExerciseVideoAnalysisRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import java.time.OffsetDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.Limit;

/**
 * A expiração de mídia por retenção (LGPD).
 *
 * <p>Este é o único ponto do sistema que apaga arquivo do usuário sem ele pedir, e o que apaga é
 * irrecuperável. Duas coisas precisam estar certas e nenhuma se manifesta em erro quando está
 * errada: a <b>janela de cada tipo</b> ({@code expireVideos} e {@code expirePhotos} são quase
 * idênticos, e trocar 30 por 90 apaga vídeo dois meses antes da hora) e a <b>preservação do
 * resultado</b> — o que expira é o arquivo, não a análise que o usuário já viu.
 */
class MediaRetentionServiceTest {

    private static final int VIDEO_DAYS = 30;
    private static final int MEAL_PHOTO_DAYS = 90;

    private ExerciseVideoAnalysisRepository videos;
    private MealPhotoAnalysisRepository photos;
    private MediaStorage storage;
    private MediaRetentionService service;

    @BeforeEach
    void setUp() {
        videos = mock(ExerciseVideoAnalysisRepository.class);
        photos = mock(MealPhotoAnalysisRepository.class);
        storage = mock(MediaStorage.class);
        service = new MediaRetentionService(
                videos, photos, storage, new RetentionProperties(VIDEO_DAYS, MEAL_PHOTO_DAYS));

        // Nada a expirar por padrão; cada teste povoa o lado que exercita.
        when(videos.findByMediaExpiredAtIsNullAndCreatedAtBefore(any(), any()))
                .thenReturn(List.of());
        when(photos.findByMediaExpiredAtIsNullAndMediaKeyIsNotNullAndCreatedAtBefore(any(), any()))
                .thenReturn(List.of());
    }

    private static ExerciseVideoAnalysis video(String mediaKey, String overlayKey) {
        ExerciseVideoAnalysis analysis = new ExerciseVideoAnalysis();
        analysis.setMediaKey(mediaKey);
        analysis.setOverlayVideoKey(overlayKey);
        analysis.setResultJson("{\"score\":82}");
        analysis.setScore(82);
        return analysis;
    }

    private static MealPhotoAnalysis photo(String mediaKey, String illustratedKey) {
        MealPhotoAnalysis analysis = new MealPhotoAnalysis();
        analysis.setMediaKey(mediaKey);
        analysis.setIllustratedMediaKey(illustratedKey);
        analysis.setItemsJson("[{\"nome\":\"arroz\"}]");
        return analysis;
    }

    private void videosToExpire(ExerciseVideoAnalysis... expired) {
        when(videos.findByMediaExpiredAtIsNullAndCreatedAtBefore(any(), any()))
                .thenReturn(List.of(expired));
    }

    private void photosToExpire(MealPhotoAnalysis... expired) {
        when(photos.findByMediaExpiredAtIsNullAndMediaKeyIsNotNullAndCreatedAtBefore(any(), any()))
                .thenReturn(List.of(expired));
    }

    /** O corte que o serviço pediu ao repositório, dado que ele chama {@code now()} por dentro. */
    private OffsetDateTime videoCutoff() {
        ArgumentCaptor<OffsetDateTime> captor = ArgumentCaptor.forClass(OffsetDateTime.class);
        verify(videos)
                .findByMediaExpiredAtIsNullAndCreatedAtBefore(captor.capture(), any(Limit.class));
        return captor.getValue();
    }

    private OffsetDateTime photoCutoff() {
        ArgumentCaptor<OffsetDateTime> captor = ArgumentCaptor.forClass(OffsetDateTime.class);
        verify(photos)
                .findByMediaExpiredAtIsNullAndMediaKeyIsNotNullAndCreatedAtBefore(captor.capture(), any(Limit.class));
        return captor.getValue();
    }

    /** Aproxima o corte esperado com folga para o tempo de execução do teste. */
    private static void assertCutoffIsDaysAgo(OffsetDateTime cutoff, int days) {
        OffsetDateTime esperado = OffsetDateTime.now().minusDays(days);
        assertThat(cutoff).isBetween(esperado.minusMinutes(1), esperado.plusMinutes(1));
    }

    @Nested
    @DisplayName("as janelas de retenção")
    class Janelas {

        @Test
        @DisplayName("vídeo expira pela janela curta")
        void videoUsesVideoDays() {
            // Vídeo é potencialmente biométrico: é o que justifica a janela mais curta.
            service.sweep();

            assertCutoffIsDaysAgo(videoCutoff(), VIDEO_DAYS);
        }

        @Test
        @DisplayName("foto de refeição expira pela janela longa")
        void photoUsesMealPhotoDays() {
            // Trocado com o de cima, o teste passa a apagar foto aos 30 dias e vídeo aos 90 —
            // exatamente o engano que dois métodos quase idênticos convidam.
            service.sweep();

            assertCutoffIsDaysAgo(photoCutoff(), MEAL_PHOTO_DAYS);
        }

        @Test
        @DisplayName("configuração ausente cai no padrão, não em zero")
        void zeroFallsBackToDefaults() {
            // Com 0 o corte seria "agora" e a primeira varredura apagaria a mídia de todo mundo,
            // inclusive a de hoje. O record precisa segurar isso.
            RetentionProperties semConfig = new RetentionProperties(0, 0);

            assertThat(semConfig.videoDays()).isEqualTo(VIDEO_DAYS);
            assertThat(semConfig.mealPhotoDays()).isEqualTo(MEAL_PHOTO_DAYS);
        }
    }

    @Nested
    @DisplayName("ao expirar um vídeo")
    class Video {

        @Test
        @DisplayName("apaga o original e o overlay, e preserva a análise")
        void deletesBothKeys() {
            ExerciseVideoAnalysis analysis = video("videos/a.mp4", "videos/a-overlay.mp4");
            videosToExpire(analysis);

            service.sweep();

            verify(storage).delete("videos/a.mp4");
            // O overlay é um segundo arquivo derivado; esquecê-lo deixaria lixo pago no storage
            // para sempre, já que a linha sai do alcance da próxima varredura.
            verify(storage).delete("videos/a-overlay.mp4");

            assertThat(analysis.getMediaExpiredAt()).isNotNull();
            // O que o usuário viu continua lá: expira o arquivo, não o resultado.
            assertThat(analysis.getResultJson()).isEqualTo("{\"score\":82}");
            assertThat(analysis.getScore()).isEqualTo(82);
            verify(videos).saveAll(List.of(analysis));
        }

        @Test
        @DisplayName("sem overlay, não tenta apagar chave vazia")
        void skipsMissingOverlay() {
            // OverlayVideoKey é nulo quando o serviço de visão não gerou overlay.
            videosToExpire(video("videos/b.mp4", null));

            service.sweep();

            verify(storage).delete("videos/b.mp4");
            verify(storage, never()).delete(null);
        }
    }

    @Nested
    @DisplayName("ao expirar uma foto")
    class Foto {

        @Test
        @DisplayName("apaga o original e a versão ilustrada, e preserva os itens")
        void deletesBothKeys() {
            MealPhotoAnalysis analysis = photo("meals/a.jpg", "meals/a-ilustrada.jpg");
            photosToExpire(analysis);

            service.sweep();

            verify(storage).delete("meals/a.jpg");
            verify(storage).delete("meals/a-ilustrada.jpg");

            assertThat(analysis.getMediaExpiredAt()).isNotNull();
            // Os itens alimentam o diário e o histórico de calorias: apagá-los reescreveria
            // o passado do usuário.
            assertThat(analysis.getItemsJson()).isEqualTo("[{\"nome\":\"arroz\"}]");
            verify(photos).saveAll(List.of(analysis));
        }
    }

    @Nested
    @DisplayName("quando o storage falha")
    class StorageIndisponivel {

        @Test
        @DisplayName("marca a linha como expirada mesmo assim")
        void marksRowAnyway() {
            // O objeto pode já não existir. Se a falha impedisse a marcação, a mesma linha
            // voltaria em toda varredura, para sempre, tentando apagar o que não está lá.
            ExerciseVideoAnalysis analysis = video("videos/sumiu.mp4", null);
            videosToExpire(analysis);
            doThrow(new RuntimeException("NoSuchKey")).when(storage).delete(anyString());

            assertThatCode(service::sweep).doesNotThrowAnyException();

            assertThat(analysis.getMediaExpiredAt()).isNotNull();
            verify(videos).saveAll(List.of(analysis));
        }

        @Test
        @DisplayName("uma mídia problemática não impede as seguintes do lote")
        void oneFailureDoesNotBlockTheBatch() {
            ExerciseVideoAnalysis ruim = video("videos/ruim.mp4", null);
            ExerciseVideoAnalysis boa = video("videos/boa.mp4", null);
            videosToExpire(ruim, boa);
            doThrow(new RuntimeException("NoSuchKey")).when(storage).delete("videos/ruim.mp4");

            service.sweep();

            verify(storage).delete("videos/boa.mp4");
            assertThat(boa.getMediaExpiredAt()).isNotNull();
        }
    }

    @Test
    @DisplayName("uma falha de banco não propaga para o scheduler")
    void databaseFailureDoesNotPropagate() {
        when(videos.findByMediaExpiredAtIsNullAndCreatedAtBefore(any(), any()))
                .thenThrow(new RuntimeException("deadlock detected"));

        assertThatCode(service::sweep).doesNotThrowAnyException();

        // Documentando o que o catch da varredura implica hoje: ele envolve os dois lotes, então
        // a falha no de vídeos salta o de fotos inteiro nesta passada. Não se perde nada — a
        // varredura é reentrante e as fotos expiram na próxima, seis horas depois —, mas o atraso
        // é invisível: só se loga quando algo expira, e aqui nada expirou.
        verify(photos, never()).findByMediaExpiredAtIsNullAndMediaKeyIsNotNullAndCreatedAtBefore(any(), any());
    }
}
