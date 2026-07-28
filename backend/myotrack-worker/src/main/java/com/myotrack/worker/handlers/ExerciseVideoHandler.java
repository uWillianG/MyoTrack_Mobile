package com.myotrack.worker.handlers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.AnalysisJobType;
import com.myotrack.domain.entity.AnalysisJob;
import com.myotrack.domain.entity.ExerciseVideoAnalysis;
import com.myotrack.infrastructure.repository.ExerciseVideoAnalysisRepository;
import com.myotrack.infrastructure.vision.VisionClient;
import com.myotrack.infrastructure.vision.VisionClient.VisionAnalysis;
import com.myotrack.worker.JobHandler;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Analisa a execução de um exercício a partir do vídeo enviado pelo usuário.
 *
 * <p>Ao contrário dos outros handlers, aqui não há chamada de LLM: quem faz o trabalho é o
 * serviço de visão (MediaPipe Pose), que conta repetições, pontua a execução e desenha o
 * esqueleto sobre o vídeo. Este handler é a ponte entre a fila e esse serviço.
 *
 * <p>O score pode vir nulo de propósito. Vídeo tremido, corpo cortado no enquadramento ou luz
 * ruim tornam a pose não confiável, e <b>nota inventada é pior que nota nenhuma</b> quando o
 * usuário vai mudar como levanta peso por causa dela — o motivo vai em
 * {@code notEvaluableReason}, dentro do resultado.
 */
@Component
public class ExerciseVideoHandler implements JobHandler {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final ExerciseVideoAnalysisRepository analyses;
    private final VisionClient vision;

    public ExerciseVideoHandler(
            ExerciseVideoAnalysisRepository analyses, VisionClient vision) {
        this.analyses = analyses;
        this.vision = vision;
    }

    @Override
    public AnalysisJobType type() {
        return AnalysisJobType.EXERCISE_VIDEO;
    }

    @Override
    @Transactional
    public String handle(AnalysisJob job) {
        final UUID userId = job.getUserId();

        final String mediaKey = job.getMediaKey();
        if (mediaKey == null || mediaKey.isBlank()) {
            throw new IllegalStateException("O vídeo do exercício não foi encontrado.");
        }

        if (!vision.isConfigured()) {
            // Erro de negócio: reprocessar não faz o serviço aparecer.
            throw new IllegalStateException(
                    "A análise de vídeo está indisponível no momento.");
        }

        final String exercise = exerciseOf(job);
        final VisionAnalysis result = vision.analyze(mediaKey, exercise);

        if (result == null) {
            // Falha de chamada pode ser passageira (serviço reiniciando, fila cheia): não é
            // IllegalStateException, então o poller tenta de novo.
            throw new IllegalArgumentException(
                    "O serviço de análise não respondeu. Tentaremos de novo.");
        }

        final ExerciseVideoAnalysis entity = new ExerciseVideoAnalysis();
        entity.setUserId(userId);
        entity.setAnalysisJobId(job.getId());
        entity.setMediaKey(mediaKey);
        entity.setOverlayVideoKey(result.overlayVideoKey());
        entity.setAnalyzedExercise(exercise);
        entity.setScore(result.score());
        entity.setRepCount(result.repCount());
        entity.setResultJson(
                result.resultJson() == null || result.resultJson().isBlank()
                        ? "{}"
                        : result.resultJson());

        return "{\"exerciseVideoAnalysisId\":\"%s\"}".formatted(analyses.save(entity).getId());
    }

    /** O slug do exercício, gravado pelo controller no {@code inputJson} do job. */
    private static String exerciseOf(AnalysisJob job) {
        final String input = job.getInputJson();
        if (input == null || input.isBlank()) {
            throw new IllegalStateException("O exercício a analisar não foi informado.");
        }
        try {
            final String exercise = MAPPER.readTree(input).path("exercise").asText(null);
            if (exercise == null || exercise.isBlank()) {
                throw new IllegalStateException("O exercício a analisar não foi informado.");
            }
            return exercise;
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("O exercício a analisar não pôde ser lido.", e);
        }
    }
}
