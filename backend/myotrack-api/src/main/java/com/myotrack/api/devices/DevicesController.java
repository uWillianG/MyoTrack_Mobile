package com.myotrack.api.devices;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.DevicePlatform;
import com.myotrack.domain.entity.DeviceToken;
import com.myotrack.infrastructure.repository.DeviceTokenRepository;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Onde o app diz para qual endereço notificar.
 *
 * <p>O app registra a cada abertura, e não uma vez só: o FCM rotaciona o token por conta própria
 * (reinstalação, restauração de backup, limpeza de dados) e não avisa ninguém. Um registro único no
 * primeiro login renderia um aparelho que silenciosamente para de receber notificação meses depois.
 */
@RestController
@RequestMapping("/api/devices")
@Validated
public class DevicesController {

    private static final Logger log = LoggerFactory.getLogger(DevicesController.class);

    private final DeviceTokenRepository tokens;

    public DevicesController(DeviceTokenRepository tokens) {
        this.tokens = tokens;
    }

    /**
     * Registra ou atualiza o token deste aparelho.
     *
     * <p>Idempotente, e é o que sustenta o registro a cada abertura: chamar com o mesmo token
     * apenas move o {@code LastSeenAt}.
     *
     * <p>Quando o token já existe em outro usuário, a linha é <b>reatribuída</b>. É o aparelho que
     * trocou de conta, e o FCM manteve o token — inserir uma segunda linha faria o aparelho passar
     * a receber as notificações das duas pessoas.
     */
    @PostMapping
    @Transactional
    public ResponseEntity<Void> register(@RequestBody RegisterRequest request) {
        final UUID userId = CurrentUser.id();

        final DeviceToken device = tokens.findByToken(request.token())
                .orElseGet(() -> {
                    final DeviceToken novo = new DeviceToken();
                    novo.setToken(request.token());
                    return novo;
                });

        if (device.getId() != null && !userId.equals(device.getUserId())) {
            log.info("Token de aparelho reatribuído do usuário {} para {}.",
                    device.getUserId(), userId);
        }

        device.setUserId(userId);
        device.setPlatform(request.platform());
        device.setLastSeenAt(OffsetDateTime.now());
        tokens.save(device);

        return ResponseEntity.noContent().build();
    }

    /**
     * Remove o token. O app chama ao sair da conta.
     *
     * <p>Sem isto o aparelho continuaria recebendo o "seu relatório está pronto" de quem já saiu,
     * na tela de bloqueio de quem entrou depois.
     *
     * <p>204 mesmo quando o token não existe: sair da conta não pode falhar por causa de um token
     * que o FCM já rotacionou, e o resultado desejado — não receber mais — está satisfeito.
     */
    @DeleteMapping
    @Transactional
    public ResponseEntity<Void> unregister(@RequestBody UnregisterRequest request) {
        tokens.deleteByToken(request.token());
        return ResponseEntity.noContent().build();
    }

    public record RegisterRequest(
            @NotBlank(message = "Token do aparelho é obrigatório.") String token,
            @NotNull(message = "Plataforma é obrigatória.") DevicePlatform platform) {
    }

    public record UnregisterRequest(
            @NotBlank(message = "Token do aparelho é obrigatório.") String token) {
    }
}
