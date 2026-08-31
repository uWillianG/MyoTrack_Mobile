import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'auth/token_store.dart';
import 'db/local_database.dart';
import 'jobs/job_watcher.dart';
import 'network/api_client.dart';
import 'sync/background_sync.dart';
import 'sync/sync_queue.dart';
import 'sync/sync_scheduler.dart';

/// Providers de infraestrutura, disponíveis para o app inteiro.
///
/// São declarados à mão (e não via `riverpod_generator`) porque formam o grafo raiz e
/// precisam ser sobrescritos nos testes com `ProviderScope(overrides: [...])`.

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Câmera e galeria do sistema. Serve foto de refeição (B7) e vídeo de execução (B9), por isso
/// mora aqui e não dentro de uma das duas features.
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// Versão, build e nome do pacote, lidos do próprio binário.
///
/// **Assíncrono porque a leitura é do lado nativo**, e por isso é um `FutureProvider` e não uma
/// constante: no Android e no iOS o valor vem do manifesto, não do Dart. O rodapé da aba Conta
/// espera por ele sem mostrar nada — uma versão errada por um instante é pior que nenhuma numa
/// linha cuja única função é ser copiada para um relato de problema.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(tokenStore: ref.watch(tokenStoreProvider));
  client.onSessionExpired = () async {
    // Limpar a sessão faz o authStateProvider reavaliar, e o go_router
    // redireciona para o login sozinho.
    await ref.read(tokenStoreProvider).clear();
    ref.invalidate(authStateProvider);
  };
  return client;
});

final jobWatcherProvider = Provider<JobWatcher>(
  (ref) => JobWatcher(ref.watch(apiClientProvider)),
);

/// Banco local (Drift). Um por app: abrir o mesmo arquivo SQLite duas vezes trava.
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncSchedulerProvider = Provider<SyncScheduler>(
  (ref) => const WorkManagerSync(),
);

final syncQueueProvider = Provider<SyncQueue>(
  (ref) => SyncQueue(
    ref.watch(apiClientProvider),
    ref.watch(localDatabaseProvider),
    scheduler: ref.watch(syncSchedulerProvider),
  ),
);

/// Quantas escritas ainda não subiram — a UI avisa quando é diferente de zero.
final pendingWritesProvider = StreamProvider<int>(
  (ref) => ref.watch(syncQueueProvider).watchPendingCount(),
);

/// O que o servidor recusou e não vai voltar a tentar sozinho.
///
/// Leitura única com `autoDispose`, e não um stream sobre a tabela. São duas razões: o
/// `watch` do drift deixa um timer pendente que faz teste de widget falhar por "Pending
/// timers", e o descarte não é um evento que precise chegar à tela no instante em que
/// acontece — ele quase sempre ocorre numa sincronização em background, com o app fechado.
/// `autoDispose` faz a leitura acontecer quando alguém abre a folha da conta, que é o único
/// momento em que há alguém olhando.
final discardedWritesProvider =
    FutureProvider.autoDispose<List<DiscardedWrite>>(
      (ref) => ref.watch(syncQueueProvider).discarded(),
    );

/// Há sessão válida guardada? É o que a guarda de rota do go_router observa.
final authStateProvider = FutureProvider<bool>(
  (ref) => ref.watch(tokenStoreProvider).isAuthenticated,
);

/// Papéis do usuário atual — decide se o item de revisão aparece no menu.
final userRolesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(tokenStoreProvider).roles(),
);

/// E-mail do usuário atual. Alimenta as iniciais do avatar da barra superior.
final userEmailProvider = FutureProvider<String?>(
  (ref) => ref.watch(tokenStoreProvider).email(),
);
