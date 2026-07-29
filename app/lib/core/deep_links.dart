import 'env.dart';

/// Traduz um link que chega de fora para um caminho de rota do app.
///
/// Três formatos precisam funcionar, e eles chegam com formas bem diferentes:
///
/// - **App Link / Universal Link** — `https://myotrack.app/redefinir-senha?uid=…`. É o que o
///   backend põe nos e-mails, e o que abre o app direto quando o domínio está verificado.
/// - **Esquema próprio com host** — `myotrack://redefinir-senha?uid=…`. É a forma que as
///   pessoas escrevem naturalmente, e a que uma SPA redirecionando emitiria. Aqui o
///   "redefinir-senha" cai no **host** da URI, e o path fica vazio — despachar sem tratar
///   levaria à raiz, e o link pareceria ignorado.
/// - **Esquema próprio sem host** — `myotrack:///redefinir-senha?uid=…`. Formalmente mais
///   correta, e a que um gerador de URI produz.
///
/// Devolve null quando o link não é nosso: melhor não navegar do que navegar para o lugar
/// errado por causa de um link de terceiro que o sistema entregou por engano.
String? deepLinkPath(Uri uri) {
  final scheme = uri.scheme.toLowerCase();

  final String path;
  if (scheme == 'http' || scheme == 'https') {
    if (!_isOurHost(uri.host)) {
      return null;
    }
    path = uri.path;
  } else if (scheme == Env.deepLinkScheme) {
    // Com host preenchido ele É o primeiro segmento; sem host, o path já vem inteiro.
    path = uri.host.isEmpty ? uri.path : '/${uri.host}${uri.path}';
  } else if (scheme.isEmpty) {
    // Já é um caminho interno — nada a traduzir.
    path = uri.path;
  } else {
    return null;
  }

  final normalized = _canonical(path);
  return uri.hasQuery ? '$normalized?${uri.query}' : normalized;
}

/// Caminho com barra inicial e sem barra final.
///
/// A barra final não é detalhe estético: o Flutter entrega `myotrack://diario` ao roteador
/// como `/diario/`, e o go_router não casa isso com a rota `/diario` — o link abria o app
/// e caía em "Rota não encontrada". Descoberto rodando o link no emulador.
String _canonical(String path) {
  if (path.isEmpty || path == '/') {
    return '/';
  }
  final withSlash = _withLeadingSlash(path);
  return withSlash.endsWith('/')
      ? withSlash.substring(0, withSlash.length - 1)
      : withSlash;
}

/// O domínio do app, e os subdomínios dele.
///
/// Compara o host inteiro em vez de usar `endsWith` puro: `endsWith('myotrack.app')` daria
/// verdadeiro para `evilmyotrack.app`, e aí um link de terceiro abriria o app.
bool _isOurHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == _domain || normalized.endsWith('.$_domain');
}

const String _domain = 'myotrack.app';

String _withLeadingSlash(String path) => path.startsWith('/') ? path : '/$path';
