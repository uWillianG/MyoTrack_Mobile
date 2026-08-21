import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/session.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';

/// Quem é o titular desta sessão — `GET /api/privacy/account`.
///
/// Escrito à mão em vez de gerado: são três campos, e um modelo do freezed aqui só
/// acrescentaria dois arquivos gerados ao repositório.
class AccountSummary {
  const AccountSummary({
    required this.email,
    required this.createdAt,
    required this.hasPassword,
  });

  final String? email;
  final DateTime? createdAt;

  /// **Decide o que o diálogo de exclusão pede.** Com senha, ele pede a senha; sem — conta de
  /// Google ou Apple —, o próprio e-mail. Enquanto o app não sabia disto, a tela pedia "senha
  /// ou e-mail" e metade das pessoas lia a instrução errada num diálogo irreversível.
  final bool hasPassword;

  factory AccountSummary.fromJson(Map<String, dynamic> json) => AccountSummary(
    email: json['email'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    hasPassword: json['hasPassword'] as bool? ?? false,
  );
}

/// Uma linha da trilha de consentimento — `GET /api/profile/consents`.
class ConsentEntry {
  const ConsentEntry({
    required this.type,
    required this.termsVersion,
    required this.grantedAt,
    this.revokedAt,
  });

  final String type;
  final String termsVersion;
  final DateTime? grantedAt;
  final DateTime? revokedAt;

  factory ConsentEntry.fromJson(Map<String, dynamic> json) => ConsentEntry(
    type: json['type'] as String? ?? '',
    termsVersion: json['termsVersion'] as String? ?? '',
    grantedAt: DateTime.tryParse(json['grantedAt'] as String? ?? ''),
    revokedAt: DateTime.tryParse(json['revokedAt'] as String? ?? ''),
  );

  /// O que foi autorizado, em português.
  ///
  /// Tipo desconhecido aparece cru em vez de sumir da lista: um consentimento que a pessoa
  /// deu e a tela esconde por não reconhecer o nome é pior que um rótulo feio — e é
  /// exatamente o que aconteceria no dia em que o servidor passasse a registrar um tipo novo.
  String get label => switch (type) {
    'HealthData' => 'Tratamento dos dados de saúde',
    'MediaAiAnalysis' => 'Análise de fotos e vídeos por IA',
    'TermsOfService' => 'Termos de uso',
    'PrivacyPolicy' => 'Política de privacidade',
    _ => type,
  };
}

/// Direitos do titular (LGPD).
///
/// Quase tudo mora em `/api/privacy`. A exceção é a trilha de consentimento, que fica em
/// `/api/profile/consents` porque é ali que ela é **escrita**, no cadastro do perfil — mas
/// quem a **lê** é esta tela, e por isso o método está aqui e não no repositório do perfil.
class PrivacyRepository {
  PrivacyRepository(this._api);

  final ApiClient _api;

  /// De quem é a conta desta sessão, e como ela confirma a exclusão.
  Future<AccountSummary> account() async {
    final json = await _api.get<Map<String, dynamic>>('/api/privacy/account');
    return AccountSummary.fromJson(json);
  }

  /// O que a pessoa autorizou, do aceite mais recente para o mais antigo.
  Future<List<ConsentEntry>> consents() async {
    final json = await _api.get<List<dynamic>>('/api/profile/consents');
    return [
      for (final entry in json)
        ConsentEntry.fromJson(entry as Map<String, dynamic>),
    ];
  }

  /// Apaga a conta e todos os dados, definitivamente.
  ///
  /// A [confirmation] é a senha da conta — ou, para quem entrou com Google ou Apple, o
  /// próprio e-mail: essas contas não têm senha, e sem essa alternativa o titular ficaria
  /// sem como exercer o direito de eliminação. Quem decide qual das duas serve é o servidor.
  Future<void> deleteAccount(String confirmation) => _api.delete<void>(
    '/api/privacy/account',
    body: {'password': confirmation},
  );

  /// O export inteiro, em JSON, para o app entregar como arquivo.
  Future<Map<String, dynamic>> export() =>
      _api.get<Map<String, dynamic>>('/api/privacy/export');

  /// Pede o export dos dados por e-mail.
  ///
  /// Não recebe endereço: o servidor manda sempre para o da própria conta. Aceitar um
  /// destinatário aqui transformaria o pedido numa forma de exfiltrar os dados de quem
  /// deixasse a sessão aberta.
  Future<void> emailExport() => _api.post<void>('/api/privacy/export/email');
}

final privacyRepositoryProvider = Provider<PrivacyRepository>(
  (ref) => PrivacyRepository(ref.watch(apiClientProvider)),
);

/// O resumo da conta. Falha **não** derruba a tela — ver `AccountPage`.
final accountSummaryProvider = FutureProvider<AccountSummary>(
  (ref) => ref.watch(privacyRepositoryProvider).account(),
);

final consentTrailProvider = FutureProvider<List<ConsentEntry>>(
  (ref) => ref.watch(privacyRepositoryProvider).consents(),
);

/// Para onde vai o arquivo do export.
///
/// É uma interface, e não uma chamada direta ao plugin, porque a folha de compartilhamento do
/// sistema não existe num teste de widget: sem esta costura, "baixar meus dados" seria a única
/// parte da tela que ninguém consegue exercer sem um aparelho na mão.
abstract class ExportSink {
  Future<void> deliver(String filename, String contents);
}

/// A folha de compartilhamento do sistema.
///
/// O arquivo é escrito no diretório temporário de propósito. É o único lugar que a folha
/// consegue ler sem o app pedir permissão de armazenamento, e é o que o sistema limpa sozinho
/// — um export com a vida inteira da pessoa não deve ficar parado numa pasta pública à espera
/// de quem pegar o celular. Apagá-lo aqui, logo depois de compartilhar, é que não dá: no
/// Android o app que recebeu ainda pode estar copiando.
class ShareSheetSink implements ExportSink {
  const ShareSheetSink();

  @override
  Future<void> deliver(String filename, String contents) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(contents);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: filename)],
        // O nome importa: sem ele o arquivo chega ao destino como "share" ou com o nome
        // temporário, e a pessoa fica com um JSON anônimo na pasta de downloads.
        fileNameOverrides: [filename],
        subject: filename,
      ),
    );
  }
}

final exportSinkProvider = Provider<ExportSink>(
  (ref) => const ShareSheetSink(),
);

/// Estado dos dois pedidos de export.
///
/// **Dois campos e não um.** Baixar e enviar por e-mail são botões vizinhos: com um único
/// "ocupado", tocar em um deles acenderia o rodinho do outro.
class ExportState {
  const ExportState({this.emailing = false, this.downloading = false});

  final bool emailing;
  final bool downloading;

  bool get busy => emailing || downloading;
}

class ExportController extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  /// Devolve a mensagem a mostrar — de sucesso ou de erro.
  Future<String> emailToAccount() async {
    if (state.busy) {
      return '';
    }
    state = const ExportState(emailing: true);
    try {
      await ref.read(privacyRepositoryProvider).emailExport();
      return 'Enviamos seus dados para o e-mail da sua conta.';
    } catch (error) {
      // A mensagem do servidor distingue "SMTP indisponível neste ambiente" de falha real,
      // e é ela que o usuário precisa ler.
      return '$error';
    } finally {
      state = const ExportState();
    }
  }

  /// Baixa o export e entrega ao sistema. Devolve mensagem **só quando dá errado**.
  ///
  /// No sucesso quem confirma é a própria folha de compartilhamento, que abre por cima da
  /// tela: uma barrinha dizendo "pronto" atrás dela seria conversa com quem não está olhando.
  Future<String> download() async {
    if (state.busy) {
      return '';
    }
    state = const ExportState(downloading: true);
    try {
      final data = await ref.read(privacyRepositoryProvider).export();
      await ref
          .read(exportSinkProvider)
          .deliver(
            _filename(DateTime.now()),
            // Com recuo: é um arquivo que a pessoa pode abrir para conferir o que o app tem
            // sobre ela, e um JSON de uma linha só não se lê.
            const JsonEncoder.withIndent('  ').convert(data),
          );
      return '';
    } catch (error) {
      return '$error';
    } finally {
      state = const ExportState();
    }
  }

  /// O mesmo nome que o servidor dá ao anexo do e-mail, para os dois caminhos entregarem um
  /// arquivo com a mesma cara.
  static String _filename(DateTime now) {
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return 'myotrack-dados-${now.year}$month$day.json';
  }
}

final exportProvider = NotifierProvider<ExportController, ExportState>(
  ExportController.new,
);

/// Estado da tela de exclusão.
class DeleteAccountState {
  const DeleteAccountState({this.deleting = false, this.error});

  final bool deleting;
  final String? error;

  static const idle = DeleteAccountState();
}

class DeleteAccountController extends Notifier<DeleteAccountState> {
  @override
  DeleteAccountState build() => DeleteAccountState.idle;

  /// Devolve se a conta foi apagada.
  ///
  /// Em caso de sucesso a sessão é fechada aqui mesmo: os tokens continuariam válidos até
  /// expirar, e um app aberto com sessão de uma conta que não existe mais só produziria 404
  /// em cada tela. Quem faz isso é o `SessionCloser`, o mesmo do "Sair da conta" — e é ele
  /// que apaga também o que ficou no aparelho, sem o que a promessa de "não há cópia de
  /// segurança" seria falsa.
  Future<bool> delete(String confirmation) async {
    if (state.deleting) {
      return false;
    }
    state = const DeleteAccountState(deleting: true);

    try {
      await ref.read(privacyRepositoryProvider).deleteAccount(confirmation);

      // `notifyServer: false`: o servidor já apagou os registros de push junto com a conta,
      // e a chamada iria com o token de uma conta que não existe mais.
      await ref.read(sessionCloserProvider).close(notifyServer: false);

      state = DeleteAccountState.idle;
      return true;
    } catch (error) {
      state = DeleteAccountState(
        deleting: false,
        // A mensagem do servidor é a que orienta: ela distingue "senha incorreta" de
        // "digite o e-mail da sua conta", e é ela que corrige o app quando o resumo da conta
        // não carregou e a tela teve de adivinhar o que pedir.
        error: '$error',
      );
      return false;
    }
  }
}

final deleteAccountProvider =
    NotifierProvider<DeleteAccountController, DeleteAccountState>(
      DeleteAccountController.new,
    );
