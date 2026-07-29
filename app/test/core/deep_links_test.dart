import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/deep_links.dart';

/// O link de redefinição de senha sai do backend como https e pode chegar ao app por três
/// formas diferentes. Todas precisam cair na mesma rota, com a query intacta — é ela que
/// carrega o uid e o token.
void main() {
  const query = 'uid=abc&token=xyz';

  group('App Link (https)', () {
    test('vira caminho interno com a query preservada', () {
      expect(
        deepLinkPath(Uri.parse('https://myotrack.app/redefinir-senha?$query')),
        '/redefinir-senha?$query',
      );
    });

    test('subdomínio nosso também vale', () {
      expect(
        deepLinkPath(Uri.parse('https://www.myotrack.app/dieta')),
        '/dieta',
      );
    });

    test('domínio de terceiro é recusado', () {
      // Sem isto, qualquer site poderia abrir uma tela do app.
      expect(
        deepLinkPath(Uri.parse('https://exemplo.com/redefinir-senha')),
        isNull,
      );
    });

    test('domínio parecido não passa', () {
      // endsWith puro deixaria "evilmyotrack.app" entrar.
      expect(deepLinkPath(Uri.parse('https://evilmyotrack.app/dieta')), isNull);
    });
  });

  group('esquema próprio', () {
    test('com host: o host É o primeiro segmento', () {
      // myotrack://redefinir-senha → host "redefinir-senha", path vazio. Sem tratar, o
      // link cairia na raiz e pareceria ignorado.
      expect(
        deepLinkPath(Uri.parse('myotrack://redefinir-senha?$query')),
        '/redefinir-senha?$query',
      );
    });

    test('sem host: o path já vem inteiro', () {
      expect(
        deepLinkPath(Uri.parse('myotrack:///redefinir-senha?$query')),
        '/redefinir-senha?$query',
      );
    });

    test('host mais path continuam juntos', () {
      expect(deepLinkPath(Uri.parse('myotrack://treino/hoje')), '/treino/hoje');
    });

    test('esquema alheio é recusado', () {
      expect(deepLinkPath(Uri.parse('outroapp://redefinir-senha')), isNull);
    });
  });

  group('barra final', () {
    // O Flutter entrega `myotrack://diario` ao roteador como `/diario/`, e o go_router não
    // casa isso com a rota `/diario` — o link abria o app em "Rota não encontrada".
    // Descoberto rodando o link de verdade no emulador.
    test('é removida', () {
      expect(deepLinkPath(Uri.parse('/diario/')), '/diario');
      expect(deepLinkPath(Uri.parse('https://myotrack.app/dieta/')), '/dieta');
      expect(deepLinkPath(Uri.parse('myotrack://diario/')), '/diario');
    });

    test('com query, a barra some e a query fica', () {
      expect(
        deepLinkPath(Uri.parse('/redefinir-senha/?$query')),
        '/redefinir-senha?$query',
      );
    });

    test('a raiz continua sendo /', () {
      expect(deepLinkPath(Uri.parse('/')), '/');
    });
  });

  group('bordas', () {
    test('raiz vira /', () {
      expect(deepLinkPath(Uri.parse('myotrack://')), '/');
      expect(deepLinkPath(Uri.parse('https://myotrack.app')), '/');
    });

    test('caminho interno passa intacto', () {
      expect(deepLinkPath(Uri.parse('/dieta')), '/dieta');
    });
  });
}
