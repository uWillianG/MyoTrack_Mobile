import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../providers.dart';

/// De onde vem o endereço de push deste aparelho.
///
/// É interface pelo mesmo motivo da `RestAlarm`: o token vem do FCM por canal de plataforma, e
/// teste de unidade não tem quem responda. A implementação real só existe no aparelho — e, hoje,
/// ainda não existe: depende de um projeto no Firebase. Ver [UnavailablePushTokens].
abstract class PushTokenSource {
  /// Pede autorização para notificar. Devolve se é possível.
  ///
  /// No iOS a recusa é a resposta padrão do sistema, então `false` é resultado comum e não erro.
  Future<bool> requestPermission();

  /// O token atual, ou `null` quando não há autorização ou o provedor não está configurado.
  Future<String?> token();
}

/// Nenhum token, porque não há provedor configurado.
///
/// É o que roda enquanto o projeto no Firebase não existe. Devolver `null` em vez de lançar é
/// deliberado: o registro é secundário: um app que não consegue registrar push tem de continuar
/// funcionando inteiro, e quem chama não deveria precisar saber se há provedor.
class UnavailablePushTokens implements PushTokenSource {
  const UnavailablePushTokens();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;
}

/// Mantém o backend sabendo para onde notificar este aparelho.
///
/// O registro é refeito a cada abertura do app, e não uma vez no primeiro login: o FCM rotaciona
/// o token por conta própria — reinstalação, restauração de backup, limpeza de dados — e não avisa
/// ninguém. Registrar só uma vez renderia um aparelho que silenciosamente para de receber
/// notificação meses depois. O endpoint é idempotente justamente para suportar isso.
class DeviceRegistrar {
  DeviceRegistrar(this._api, this._tokens);

  final ApiClient _api;
  final PushTokenSource _tokens;

  /// Nome que o backend espera em `DevicePlatform` — o wire name do enum, não o nome do Dart.
  ///
  /// Lê `defaultTargetPlatform` e não `Platform.isAndroid`, pelo mesmo motivo da `RestAlarm`:
  /// aquele é sobrescrevível em teste, e o desenvolvimento aqui acontece no Windows, onde
  /// `Platform` responderia sempre desktop e o registro nunca seria exercitado.
  static String? get _platform {
    if (kIsWeb) {
      return null;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      // Desktop cai aqui, no `flutter run -d windows`. Sem push, e sem chamada: o backend
      // recusaria a plataforma com 400, e um 400 no login parece bug de autenticação.
      _ => null,
    };
  }

  /// Registra este aparelho. Chamado depois de autenticar e a cada abertura.
  ///
  /// **Nunca lança.** Uma falha aqui não pode impedir a entrada na conta: quem acabou de digitar
  /// a senha certa tem de chegar à tela inicial mesmo que o registro de push falhe, e o pior
  /// resultado aceitável é ficar sem notificação até a próxima abertura.
  Future<bool> register() async {
    final platform = _platform;
    if (platform == null) {
      return false;
    }

    try {
      if (!await _tokens.requestPermission()) {
        return false;
      }

      final token = await _tokens.token();
      if (token == null || token.isEmpty) {
        return false;
      }

      await _api.post<void>(
        '/api/devices',
        body: {'token': token, 'platform': platform},
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('Registro de push falhou: ${e.message}');
      return false;
    }
  }

  /// Remove o registro. Chamado ao sair da conta, **antes** de descartar os tokens de sessão.
  ///
  /// Antes porque a chamada precisa ir autenticada. Sem ela o aparelho continuaria recebendo o
  /// "seu relatório está pronto" de quem saiu — na tela de bloqueio de quem entrar depois, já que
  /// o token pertence ao aparelho e não à conta.
  Future<void> unregister() async {
    try {
      final token = await _tokens.token();
      if (token == null || token.isEmpty) {
        return;
      }
      await _api.delete<void>('/api/devices', body: {'token': token});
    } on ApiException catch (e) {
      // Sair da conta não pode falhar por isto. O token de sessão será descartado de todo jeito,
      // e o registro órfão morre na próxima tentativa de envio.
      debugPrint('Remoção do registro de push falhou: ${e.message}');
    }
  }
}

/// Trocar por uma fonte real de token quando houver projeto no Firebase é a única mudança
/// necessária aqui — o resto do fluxo já está de pé e testado.
final pushTokenSourceProvider = Provider<PushTokenSource>(
  (ref) => const UnavailablePushTokens(),
);

final deviceRegistrarProvider = Provider<DeviceRegistrar>(
  (ref) => DeviceRegistrar(
    ref.watch(apiClientProvider),
    ref.watch(pushTokenSourceProvider),
  ),
);
