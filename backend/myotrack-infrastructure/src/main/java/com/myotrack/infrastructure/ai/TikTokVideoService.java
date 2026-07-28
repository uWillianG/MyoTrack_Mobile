package com.myotrack.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myotrack.domain.entity.Exercise;
import com.myotrack.infrastructure.repository.ExerciseRepository;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Resolve um vídeo explicativo do TikTok para cada exercício do catálogo, uma única vez: o link
 * fica salvo em {@code Exercise.tutorialVideoUrl} e é compartilhado por todos os usuários.
 *
 * <p>Best-effort — o TikTok não tem API pública de busca, então o serviço lê o HTML da página de
 * busca e valida o primeiro vídeo encontrado via oEmbed (essa sim, API oficial). Se nada for
 * encontrado, o exercício fica sem link e o cliente cai para a URL de busca.
 *
 * <p>Porte de MyoTrack.Infrastructure/Ai/TikTokVideoService.cs.
 */
@Component
public class TikTokVideoService {

    private static final Logger log = LoggerFactory.getLogger(TikTokVideoService.class);

    /** Máximo de buscas por geração de treino, para não atrasar o job. */
    private static final int MAX_LOOKUPS_PER_RUN = 12;

    private static final Pattern VIDEO_URL =
            Pattern.compile("https://www\\.tiktok\\.com/@[A-Za-z0-9._\\-]+/video/\\d+");

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final ExerciseRepository exercises;
    private final RestClient restClient;

    public TikTokVideoService(ExerciseRepository exercises, RestClient.Builder restClientBuilder) {
        this.exercises = exercises;
        this.restClient = restClientBuilder.build();
    }

    public static String buildSearchQuery(String exerciseName) {
        return "como fazer %s academia".formatted(exerciseName);
    }

    public static String buildSearchUrl(String exerciseName) {
        return "https://www.tiktok.com/search?q=" + encode(buildSearchQuery(exerciseName));
    }

    /**
     * Extrai a primeira URL de vídeo do HTML da página de busca. O JSON embutido pelo TikTok
     * costuma escapar as barras como {@code /} ou {@code \/}, então normaliza antes.
     */
    public static String extractFirstVideoUrl(String html) {
        if (html == null || html.isEmpty()) {
            return null;
        }
        String normalized = html
                .replaceAll("(?i)\\\\u002F", "/")
                .replace("\\/", "/");

        Matcher matcher = VIDEO_URL.matcher(normalized);
        return matcher.find() ? matcher.group() : null;
    }

    /** Preenche o vídeo dos exercícios que ainda não têm um salvo. */
    public void resolveMissing(Collection<Integer> exerciseIds) {
        if (exerciseIds == null || exerciseIds.isEmpty()) {
            return;
        }

        List<Exercise> pending = exercises.findAllById(exerciseIds).stream()
                .filter(e -> e.getTutorialVideoUrl() == null)
                .limit(MAX_LOOKUPS_PER_RUN)
                .toList();
        if (pending.isEmpty()) {
            return;
        }

        for (Exercise exercise : pending) {
            try {
                String url = resolveOne(exercise.getName());
                if (url == null) {
                    log.info("Nenhum vídeo do TikTok encontrado para '{}'.", exercise.getName());
                    continue;
                }

                exercise.setTutorialVideoUrl(url);
                exercises.save(exercise);
                log.info("Vídeo salvo para '{}': {}", exercise.getName(), url);
            } catch (Exception e) {
                // Falha de rede ou bloqueio do TikTok não pode derrubar a geração do treino.
                log.warn("Falha ao buscar vídeo do TikTok para '{}': {}", exercise.getName(), e.getMessage());
            }
        }
    }

    private String resolveOne(String exerciseName) {
        String html = restClient.get()
                .uri(buildSearchUrl(exerciseName))
                .retrieve()
                .body(String.class);

        String candidate = extractFirstVideoUrl(html);
        if (candidate == null) {
            return null;
        }

        // oEmbed é a API oficial: confirma que o vídeo existe e é público.
        String oembed = restClient.get()
                .uri("https://www.tiktok.com/oembed?url=" + encode(candidate))
                .retrieve()
                .body(String.class);

        try {
            return MAPPER.readTree(oembed).hasNonNull("title") ? candidate : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static String encode(String value) {
        // URLEncoder usa o esquema de formulário, onde espaço vira '+'; a query do TikTok
        // espera %20, como o Uri.EscapeDataString do .NET produzia.
        return URLEncoder.encode(value, StandardCharsets.UTF_8).replace("+", "%20");
    }
}
