package com.myotrack.infrastructure.push;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.myotrack.domain.DevicePlatform;
import com.myotrack.domain.entity.DeviceToken;
import com.myotrack.infrastructure.repository.DeviceTokenRepository;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * O envio para todos os aparelhos de um usuário.
 *
 * <p>Duas garantias, e as duas existem porque quem chama é um handler de job já concluído:
 * <b>nada aqui lança</b> (uma exceção marcaria como falho um trabalho que ficou pronto, e a nova
 * tentativa pagaria outra chamada de LLM por causa de uma notificação) e <b>token recusado é
 * removido</b> (sem isso o lixo acumula para sempre, porque o provedor só denuncia um token morto
 * no instante em que se tenta usá-lo).
 */
class UserPushNotifierTest {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private static final PushMessage MENSAGEM =
            new PushMessage("Seu treino está pronto", "Bom treino.", "/treino");

    private DeviceTokenRepository tokens;
    private PushSender sender;
    private UserPushNotifier notifier;

    @BeforeEach
    void setUp() {
        tokens = mock(DeviceTokenRepository.class);
        sender = mock(PushSender.class);
        notifier = new UserPushNotifier(tokens, sender);

        when(sender.send(anyCollection(), any())).thenReturn(List.of());
    }

    private static DeviceToken device(String token) {
        DeviceToken device = new DeviceToken();
        device.setId(UUID.randomUUID());
        device.setUserId(USER_ID);
        device.setToken(token);
        device.setPlatform(DevicePlatform.ANDROID);
        return device;
    }

    private void userHas(DeviceToken... devices) {
        when(tokens.findByUserId(USER_ID)).thenReturn(List.of(devices));
    }

    @Test
    @DisplayName("envia para todos os aparelhos do usuário")
    void sendsToEveryDevice() {
        // Celular e tablet, ou o aparelho novo antes de o antigo expirar: mandar só para um
        // deixaria a notificação chegando no que a pessoa não está usando.
        DeviceToken celular = device("token-celular");
        DeviceToken tablet = device("token-tablet");
        userHas(celular, tablet);

        notifier.notifyUser(USER_ID, MENSAGEM);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<DeviceToken>> alvos = ArgumentCaptor.forClass(List.class);
        verify(sender).send(alvos.capture(), any());
        assertThat(alvos.getValue()).containsExactly(celular, tablet);
    }

    @Test
    @DisplayName("sem aparelho registrado, não chama o provedor")
    void noDevicesNoCall() {
        // Estado normal, não erro: ninguém é obrigado a autorizar notificação, e no iOS a
        // recusa é a resposta padrão do sistema.
        userHas();

        notifier.notifyUser(USER_ID, MENSAGEM);

        verify(sender, never()).send(anyCollection(), any());
    }

    @Nested
    @DisplayName("a limpeza de tokens mortos")
    class Limpeza {

        @Test
        @DisplayName("remove os que o provedor recusou de vez")
        void deletesRejected() {
            userHas(device("vivo"), device("morto"));
            when(sender.send(anyCollection(), any())).thenReturn(List.of("morto"));

            notifier.notifyUser(USER_ID, MENSAGEM);

            verify(tokens).deleteByTokenIn(List.of("morto"));
        }

        @Test
        @DisplayName("não apaga nada quando o provedor não recusou ninguém")
        void keepsEverythingOnCleanSend() {
            userHas(device("vivo"));

            notifier.notifyUser(USER_ID, MENSAGEM);

            verify(tokens, never()).deleteByTokenIn(anyCollection());
        }
    }

    @Nested
    @DisplayName("quando algo falha")
    class Falhas {

        @Test
        @DisplayName("uma exceção do provedor não sobe para quem chamou")
        void senderFailureDoesNotPropagate() {
            // Este é o ponto central: acima daqui está um job COMPLETED já gravado. Deixar a
            // exceção subir transformaria uma geração bem-sucedida em job falho.
            userHas(device("token"));
            when(sender.send(anyCollection(), any()))
                    .thenThrow(new RuntimeException("FCM 503"));

            assertThatCode(() -> notifier.notifyUser(USER_ID, MENSAGEM))
                    .doesNotThrowAnyException();
        }

        @Test
        @DisplayName("uma falha ao consultar os tokens também não sobe")
        void repositoryFailureDoesNotPropagate() {
            when(tokens.findByUserId(USER_ID)).thenThrow(new RuntimeException("connection refused"));

            assertThatCode(() -> notifier.notifyUser(USER_ID, MENSAGEM))
                    .doesNotThrowAnyException();
        }
    }
}
