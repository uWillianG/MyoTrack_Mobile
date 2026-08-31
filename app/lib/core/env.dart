import 'dart:io';

import 'package:flutter/foundation.dart';

/// Configuração de ambiente do app.
///
/// A URL da API é resolvida em um único lugar porque cada alvo alcança o backend de
/// desenvolvimento por um host diferente: o emulador Android roteia `10.0.2.2` para o
/// `localhost` da máquina, enquanto o simulador do iOS compartilha o `localhost` do host.
/// Errar isso rende um "connection refused" que parece bug de rede.
class Env {
  const Env._();

  /// Sobrescreve a URL da API em qualquer build:
  /// `flutter run --dart-define=MYOTRACK_API_URL=https://api.exemplo.com`
  static const String _override = String.fromEnvironment('MYOTRACK_API_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }
    if (kReleaseMode) {
      // Produção precisa ser HTTPS: o App Transport Security do iOS bloqueia
      // texto claro, e o Android bloqueia por padrão desde a API 28.
      return 'https://myotrack.app';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Esquema dos deep links (redefinição de senha, retorno de pagamento).
  static const String deepLinkScheme = 'myotrack';

  /// Client ID **do tipo Web** do Google Cloud, passado como
  /// `--dart-define=MYOTRACK_GOOGLE_SERVER_CLIENT_ID=...`.
  ///
  /// Sem ele o Google devolve apenas um access token, e o backend recusa o login: o
  /// endpoint `/api/auth/google/id-token` valida um **ID token**, que só é emitido quando
  /// o app declara para qual servidor ele se destina. É o erro mais comum de configuração
  /// do Google Sign-In, e falha de um jeito que não parece configuração.
  static const String googleServerClientId = String.fromEnvironment(
    'MYOTRACK_GOOGLE_SERVER_CLIENT_ID',
  );

  static bool get isGoogleSignInConfigured => googleServerClientId.isNotEmpty;

  /// Onde a aba Conta manda quem precisa de ajuda ou de ler os termos.
  ///
  /// **O e-mail é o único que funciona sem nada publicado**, e por isso é o que a tela oferece
  /// primeiro: a mensagem já sai com a versão do app e o aparelho no corpo, que é o que a
  /// primeira resposta do suporte pediria de volta. Os dois endereços de página vivem sob o
  /// mesmo domínio dos links de e-mail (`deep_links.dart`); as lojas exigem os dois de
  /// qualquer forma, e apontá-los para outro domínio é o tipo de divergência que só aparece na
  /// revisão.
  static const String supportEmail = String.fromEnvironment(
    'MYOTRACK_SUPPORT_EMAIL',
    defaultValue: 'suporte@myotrack.app',
  );

  static const String termsUrl = 'https://myotrack.app/termos';
  static const String privacyUrl = 'https://myotrack.app/privacidade';

  /// Ficha do app na App Store, para o link de avaliação.
  ///
  /// Vazia por enquanto, e é de propósito: o app ainda não foi publicado, e a Apple só emite
  /// esse número na criação da ficha. Enquanto ela estiver vazia a linha "Avaliar o app"
  /// **não aparece no iOS** — link que abre uma página de erro é pior que linha nenhuma. No
  /// Android não há equivalente a preencher: o `market://` usa o nome do pacote, que o app já
  /// sabe de si mesmo.
  static const String appStoreId = String.fromEnvironment(
    'MYOTRACK_APP_STORE_ID',
  );

  static bool get isAppStoreListed => appStoreId.isNotEmpty;

  /// Quanto o cliente espera por uma resposta comum da API.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Upload de vídeo é a única operação que legitimamente demora minutos.
  static const Duration uploadTimeout = Duration(minutes: 10);
}
