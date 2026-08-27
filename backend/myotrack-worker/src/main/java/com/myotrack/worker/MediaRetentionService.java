package com.myotrack.worker;

import com.myotrack.domain.entity.ExerciseVideoAnalysis;
import com.myotrack.domain.entity.MealPhotoAnalysis;
import com.myotrack.infrastructure.repository.ExerciseVideoAnalysisRepository;
import com.myotrack.infrastructure.repository.MealPhotoAnalysisRepository;
import com.myotrack.infrastructure.storage.MediaStorage;
import java.time.OffsetDateTime;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Política de retenção de mídia (LGPD): vídeos são potencialmente biométricos e expiram rápido;
 * fotos de refeição duram mais. Os <b>resultados</b> das análises são preservados — apenas os
 * arquivos no storage são eliminados, e a linha fica marcada com {@code MediaExpiredAt}.
 *
 * <p>Porte de MyoTrack.Worker/MediaRetentionService.cs.
 */
@Component
public class MediaRetentionService {

    private static final Logger log = LoggerFactory.getLogger(MediaRetentionService.class);

    private static final long SWEEP_INTERVAL_MS = 6 * 60 * 60 * 1000L;

    /** Lotes pequenos para a varredura não segurar transação longa nem inundar o storage. */
    private static final Limit BATCH = Limit.of(100);

    private final ExerciseVideoAnalysisRepository videos;
    private final MealPhotoAnalysisRepository photos;
    private final MediaStorage storage;
    private final RetentionProperties retention;

    public MediaRetentionService(
            ExerciseVideoAnalysisRepository videos,
            MealPhotoAnalysisRepository photos,
            MediaStorage storage,
            RetentionProperties retention) {
        this.videos = videos;
        this.photos = photos;
        this.storage = storage;
        this.retention = retention;
    }

    @Scheduled(fixedDelay = SWEEP_INTERVAL_MS, initialDelay = 60_000)
    @Transactional
    public void sweep() {
        try {
            int expiredVideos = expireVideos();
            int expiredPhotos = expirePhotos();

            if (expiredVideos > 0 || expiredPhotos > 0) {
                log.info("Retenção de mídia: {} vídeo(s) e {} foto(s) expirados.",
                        expiredVideos, expiredPhotos);
            }
        } catch (Exception e) {
            log.error("Erro na varredura de retenção de mídia.", e);
        }
    }

    private int expireVideos() {
        OffsetDateTime cutoff = OffsetDateTime.now().minusDays(retention.videoDays());
        List<ExerciseVideoAnalysis> expired =
                videos.findByMediaExpiredAtIsNullAndCreatedAtBefore(cutoff, BATCH);

        for (ExerciseVideoAnalysis video : expired) {
            deleteQuietly(video.getMediaKey());
            deleteQuietly(video.getOverlayVideoKey());
            video.setMediaExpiredAt(OffsetDateTime.now());
        }

        videos.saveAll(expired);
        return expired.size();
    }

    private int expirePhotos() {
        OffsetDateTime cutoff = OffsetDateTime.now().minusDays(retention.mealPhotoDays());
        // Só quem tem arquivo: a refeição digitada à mão vive na mesma tabela e não tem foto
        // nenhuma para apagar — marcá-la de expirada consumiria o lote sem liberar um byte.
        List<MealPhotoAnalysis> expired =
                photos.findByMediaExpiredAtIsNullAndMediaKeyIsNotNullAndCreatedAtBefore(
                        cutoff, BATCH);

        for (MealPhotoAnalysis photo : expired) {
            deleteQuietly(photo.getMediaKey());
            deleteQuietly(photo.getIllustratedMediaKey());
            photo.setMediaExpiredAt(OffsetDateTime.now());
        }

        photos.saveAll(expired);
        return expired.size();
    }

    private void deleteQuietly(String key) {
        if (key == null || key.isBlank()) {
            return;
        }
        try {
            storage.delete(key);
        } catch (Exception e) {
            // O objeto pode já não existir; a linha ainda será marcada como expirada.
            log.warn("Falha ao apagar mídia expirada {}: {}", key, e.getMessage());
        }
    }
}
