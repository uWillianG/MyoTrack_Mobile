import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Quem abre um endereço fora do app: o navegador, o cliente de e-mail, a loja.
///
/// É uma interface, e não uma chamada direta ao plugin, pela mesma razão que [ExportSink]
/// existe em `privacy_controller.dart`: nada disso responde num teste de widget. Sem a costura,
/// o bloco de suporte da aba Conta — quatro linhas, cada uma com um endereço diferente e uma
/// delas montada na hora com a versão do app — seria a única parte da tela que só dá para
/// conferir com um aparelho na mão.
///
/// **Devolve `bool` porque a recusa é silenciosa.** Um aparelho sem cliente de e-mail
/// configurado não estoura nada; ele simplesmente não abre, e sem esse retorno o toque na linha
/// não teria resposta nenhuma.
abstract class UrlOpener {
  Future<bool> open(Uri url);
}

class SystemUrlOpener implements UrlOpener {
  const SystemUrlOpener();

  @override
  Future<bool> open(Uri url) {
    // externalApplication: `mailto:` precisa sair para o cliente de e-mail e `market:` para a
    // loja. Num navegador embutido os dois não abrem coisa nenhuma.
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => const SystemUrlOpener());
