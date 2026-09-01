import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/auth/session.dart';
import 'package:myotrack/core/auth/token_store.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/notifications/push_registration.dart';
import 'package:myotrack/core/providers.dart';

/// Armazenamento em memória — o real usa Keychain/KeyStore, ausentes em teste de unidade.
class _InMemoryStorage extends FlutterSecureStorage {
  const _InMemoryStorage(this._values);

  final Map<String, String> _values;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }
}

/// Registra se ainda havia sessão no instante em que foi chamado.
///
/// É o que permite fixar a **ordem**: a remoção do registro de push precisa ir autenticada, e
/// depois de os tokens irem embora ela chegaria anônima ao servidor.
class _SpyRegistrar implements DeviceRegistrar {
  _SpyRegistrar(this._tokens);

  final TokenStore _tokens;

  bool called = false;
  bool? sessionWasAlive;

  @override
  Future<bool> register() async => false;

  @override
  Future<void> unregister() async {
    called = true;
    sessionWasAlive = await _tokens.isAuthenticated;
  }
}

/// JWT sem assinatura válida: o TokenStore só lê o payload.
String _jwtWithEmail(String email) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(json.encode(m))).replaceAll('=', '');
  return '${seg({'alg': 'HS256'})}.${seg({'sub': '1', 'email': email})}.falsa';
}

/// O fim de sessão, que é o mesmo para o "Sair da conta" e para a exclusão.
///
/// O que se testa aqui é o que ninguém vê acontecer. Um encerramento pela metade não dá erro
/// em tela nenhuma — ele deixa rastro da pessoa anterior no aparelho, e o pior deles é a fila
/// de escrita: ela guarda o corpo cru de séries e pesagens e é reenviada com *o token que
/// estiver valendo na hora*, o que faz o treino de quem saiu subir para a conta de quem entrar
/// depois no mesmo celular.
void main() {
  late Map<String, String> storage;
  late LocalDatabase db;
  late TokenStore tokens;
  late _SpyRegistrar registrar;
  late ProviderContainer container;

  setUp(() {
    storage = {
      'myotrack.accessToken': _jwtWithEmail('ana@exemplo.com'),
      'myotrack.refreshToken': 'refresh',
    };
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    tokens = TokenStore(storage: _InMemoryStorage(storage));
    registrar = _SpyRegistrar(tokens);

    container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokens),
        localDatabaseProvider.overrideWithValue(db),
        deviceRegistrarProvider.overrideWithValue(registrar),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('desregistra o push enquanto a sessão ainda vale', () async {
    await container.read(sessionCloserProvider).close();

    expect(registrar.called, isTrue);
    // Depois de limpar os tokens, a chamada iria anônima e o servidor a recusaria — e o
    // aparelho seguiria recebendo "seu relatório está pronto" de quem saiu, na tela de
    // bloqueio de quem entrar depois.
    expect(registrar.sessionWasAlive, isTrue);
  });

  test('a exclusão de conta não fala com o servidor de push', () async {
    // O purge já apagou os registros junto com a conta, e a chamada iria com o token de uma
    // conta que não existe mais: uma ida à rede segurando a tela para tomar 404.
    await container.read(sessionCloserProvider).close(notifyServer: false);

    expect(registrar.called, isFalse);
    expect(await tokens.isAuthenticated, isFalse);
  });

  test('a sessão acaba, e a guarda do router enxerga isso', () async {
    expect(await container.read(authStateProvider.future), isTrue);

    await container.read(sessionCloserProvider).close();

    // Sem o `invalidate` este valor continuaria `true` em memória e o app seguiria mostrando
    // as telas de uma sessão que não existe mais.
    expect(await container.read(authStateProvider.future), isFalse);
    expect(storage, isEmpty);
  });

  test('o e-mail da pessoa anterior não sobrevive à troca de conta', () async {
    expect(await container.read(userEmailProvider.future), 'ana@exemplo.com');

    await container.read(sessionCloserProvider).close();

    // O cabeçalho da aba Conta escreve o e-mail e desenha as iniciais a partir daqui: sem
    // invalidar, a sessão seguinte abriria com a conta de quem saiu.
    expect(await container.read(userEmailProvider.future), isNull);
  });

  test('a fila de escrita não fica esperando a próxima conta', () async {
    await db.enqueue(
      '/api/measurements',
      '{"date":"2026-08-19","weightKg":82.4}',
    );
    await db.markAchievementsSeen(const ['primeira-serie']);

    await container.read(sessionCloserProvider).close();

    expect(await db.pending(), isEmpty);
    expect(await db.seenAchievementIds(), isEmpty);
  });

  test(
    'a escrita recusada some junto — o payload dela é dado pessoal',
    () async {
      await db.enqueue(
        '/api/measurements',
        '{"date":"2026-08-19","weightKg":82.4}',
      );
      await db.discardPending(
        (await db.pending()).single,
        'Peso fora da faixa válida.',
      );

      await container.read(sessionCloserProvider).close();

      expect(await db.discarded(), isEmpty);
    },
  );
}
