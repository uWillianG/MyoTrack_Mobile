package com.myotrack.api.devices;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.DevicePlatform;
import com.myotrack.domain.entity.DeviceToken;
import com.myotrack.infrastructure.repository.DeviceTokenRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * O registro do endereço de push.
 *
 * <p>O que se testa aqui é a consequência de o token pertencer ao <b>aparelho</b> e não à pessoa.
 * O app registra a cada abertura (o FCM rotaciona o token sem avisar ninguém), então o endpoint
 * precisa ser idempotente; e o mesmo token sobrevive à troca de conta no aparelho, então precisa
 * reatribuir a linha. Inserir uma segunda em vez de reatribuir faria o aparelho receber as
 * notificações das duas contas — vazamento de dado pessoal para a pessoa errada, sem erro nenhum
 * no caminho.
 */
class DevicesControllerTest {

    private static final UUID ANA = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRUNO = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private static final String TOKEN = "fcm-token-do-aparelho";

    private DeviceTokenRepository tokens;
    private DevicesController controller;

    @BeforeEach
    void setUp() {
        tokens = mock(DeviceTokenRepository.class);
        controller = new DevicesController(tokens);

        signedInAs(ANA);

        when(tokens.findByToken(any())).thenReturn(Optional.empty());
        when(tokens.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private static void signedInAs(UUID userId) {
        Jwt jwt = Jwt.withTokenValue("t")
                .header("alg", "none")
                .subject(userId.toString())
                .build();
        SecurityContextHolder.getContext()
                .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));
    }

    /** Uma linha como o banco a devolveria: já persistida, portanto com id. */
    private static DeviceToken existing(UUID owner, OffsetDateTime lastSeenAt) {
        DeviceToken device = new DeviceToken();
        device.setId(UUID.randomUUID());
        device.setUserId(owner);
        device.setToken(TOKEN);
        device.setPlatform(DevicePlatform.ANDROID);
        device.setLastSeenAt(lastSeenAt);
        return device;
    }

    private DeviceToken saved() {
        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(tokens).save(captor.capture());
        return captor.getValue();
    }

    @Nested
    @DisplayName("no primeiro registro")
    class Primeiro {

        @Test
        @DisplayName("guarda token, plataforma e dono")
        void storesTheToken() {
            ResponseEntity<Void> response = controller.register(
                    new DevicesController.RegisterRequest(TOKEN, DevicePlatform.IOS));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

            DeviceToken device = saved();
            assertThat(device.getToken()).isEqualTo(TOKEN);
            assertThat(device.getUserId()).isEqualTo(ANA);
            // A plataforma decide qual bloco da mensagem do FCM é preenchido; guardar errado
            // entrega sem som, ou não entrega.
            assertThat(device.getPlatform()).isEqualTo(DevicePlatform.IOS);
            assertThat(device.getLastSeenAt()).isNotNull();
        }
    }

    @Nested
    @DisplayName("no registro repetido")
    class Repetido {

        @Test
        @DisplayName("é idempotente: atualiza a linha em vez de criar outra")
        void updatesInsteadOfInserting() {
            // O app registra a cada abertura. Sem isto, cada abertura criaria uma linha e a
            // pessoa receberia a mesma notificação tantas vezes quantas abriu o app.
            OffsetDateTime antiga = OffsetDateTime.now().minusDays(3);
            DeviceToken existente = existing(ANA, antiga);
            when(tokens.findByToken(TOKEN)).thenReturn(Optional.of(existente));

            controller.register(new DevicesController.RegisterRequest(TOKEN, DevicePlatform.ANDROID));

            DeviceToken device = saved();
            assertThat(device.getId()).isEqualTo(existente.getId());
            assertThat(device.getLastSeenAt()).isAfter(antiga);
        }

        @Test
        @DisplayName("reatribui o aparelho que trocou de conta")
        void reassignsOwner() {
            // Bruno saiu, Ana entrou no mesmo aparelho, e o FCM manteve o token. A linha passa a
            // ser de Ana: sem isso o aparelho receberia notificação das duas contas.
            when(tokens.findByToken(TOKEN)).thenReturn(Optional.of(existing(BRUNO, OffsetDateTime.now())));

            controller.register(new DevicesController.RegisterRequest(TOKEN, DevicePlatform.ANDROID));

            assertThat(saved().getUserId()).isEqualTo(ANA);
        }

        @Test
        @DisplayName("o mesmo token não fica com dois donos")
        void neverDuplicatesTheToken() {
            when(tokens.findByToken(TOKEN)).thenReturn(Optional.of(existing(BRUNO, OffsetDateTime.now())));

            controller.register(new DevicesController.RegisterRequest(TOKEN, DevicePlatform.ANDROID));

            // Uma única gravação, e na linha que já existia: é o índice único em "Token"
            // sendo respeitado pela aplicação, não só pelo banco.
            verify(tokens).save(any());
            verify(tokens, never()).findByUserId(any());
        }
    }

    @Nested
    @DisplayName("ao sair da conta")
    class Saida {

        @Test
        @DisplayName("remove o token")
        void deletesTheToken() {
            // Sem isto o aparelho seguiria recebendo o "seu relatório está pronto" de quem saiu,
            // na tela de bloqueio de quem entrar depois.
            ResponseEntity<Void> response = controller.unregister(
                    new DevicesController.UnregisterRequest(TOKEN));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
            verify(tokens).deleteByToken(TOKEN);
        }

        @Test
        @DisplayName("token inexistente também responde 204")
        void unknownTokenStillSucceeds() {
            // Sair da conta não pode falhar por causa de um token que o FCM já rotacionou: o
            // resultado desejado — não receber mais — já está satisfeito.
            ResponseEntity<Void> response = controller.unregister(
                    new DevicesController.UnregisterRequest("token-que-nao-existe"));

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        }
    }
}
