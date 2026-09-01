import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/jobs/job_status.dart';
import 'package:myotrack/core/jobs/job_watcher.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/core/providers.dart';

/// A base que conduz os seis jobs de IA do app, vista pelo lado de quem espera.
///
/// O que estes testes protegem é o que faltava: **a espera acaba, e dá para acabar com ela**.
/// Um job que ninguém processa deixava a tela girando pelo prazo do servidor — quinze minutos
/// —, e enquanto ela girava não havia botão nenhum, porque o passo escrito ocupa o lugar do
/// campo e do disparo. Sem sair da tela não havia saída.
class _FakeWatcher implements JobWatcher {
  /// Um acompanhamento por chamada — cancelar e pedir de novo são **dois**, e uma fonte só
  /// recusaria a segunda inscrição com um erro que não é o assunto do teste.
  final _acompanhamentos = <StreamController<JobStatus>>[];

  /// O prazo que a tela pediu. É o que prova que [JobGenerationController.deadline] não é
  /// decorativo — a análise de vídeo depende de pedir um maior que o dos outros.
  Duration? prazo;

  /// A inscrição foi desfeita? Cancelar tem de fechar o SSE, não só deixar de olhar.
  var soltou = false;

  StreamController<JobStatus> get _atual => _acompanhamentos.last;

  @override
  Stream<JobStatus> watch(
    String jobId, {
    Duration within = JobWatcher.maxWait,
  }) {
    prazo = within;
    final controller = StreamController<JobStatus>();
    controller.onCancel = () => soltou = true;
    _acompanhamentos.add(controller);
    return controller.stream;
  }

  @override
  Future<JobStatus> await_(
    String jobId, {
    Duration within = JobWatcher.maxWait,
  }) => watch(jobId, within: within).last;

  void emitir(JobState state) =>
      _atual.add(JobStatus(id: 'j1', type: 'MealPhoto', state: state));

  Future<void> concluir() async {
    emitir(JobState.completed);
    await _atual.close();
  }

  Future<void> fechar() async {
    for (final controller in _acompanhamentos) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }
}

class _FakeController extends JobGenerationController {
  var enfileirou = 0;
  var recarregou = 0;
  JobStatus? recebeu;

  @override
  Duration get deadline => const Duration(seconds: 42);

  /// O que o servidor responde ao enfileirar, quando não é um id.
  ApiException? recusa;

  @override
  Future<String> enqueue() async {
    enfileirou++;
    if (recusa case final erro?) {
      throw erro;
    }
    return 'j1';
  }

  @override
  Future<void> reload() async => recarregou++;

  @override
  void onResult(JobStatus status) => recebeu = status;
}

final _controllerProvider = NotifierProvider<_FakeController, GenerationState>(
  _FakeController.new,
);

void main() {
  late _FakeWatcher watcher;
  late ProviderContainer container;

  setUp(() {
    watcher = _FakeWatcher();
    container = ProviderContainer(
      overrides: [jobWatcherProvider.overrideWithValue(watcher)],
    );
    addTearDown(container.dispose);
    addTearDown(watcher.fechar);
  });

  _FakeController controller() => container.read(_controllerProvider.notifier);
  GenerationState state() => container.read(_controllerProvider);

  test('o prazo da tela é o prazo do acompanhamento', () async {
    // Sem isto a análise de vídeo herdaria o teto dos outros e desistiria no meio de um
    // trabalho que ainda ia entregar — ela processa o vídeo quadro a quadro antes da IA.
    unawaited(controller().start());
    await pumpEventQueue();

    expect(watcher.prazo, const Duration(seconds: 42));
  });

  test('cancelar solta a espera e devolve a tela', () async {
    unawaited(controller().start());
    await pumpEventQueue();
    watcher.emitir(JobState.processing);
    await pumpEventQueue();

    expect(state().running, isTrue);

    controller().cancel();
    await pumpEventQueue();

    expect(state().running, isFalse);
    expect(
      state().error,
      isNull,
      reason: 'desistir não é falha — não há notícia para dar em snackbar',
    );
    expect(
      watcher.soltou,
      isTrue,
      reason: 'cancelar precisa fechar a conexão, não só parar de olhar',
    );
  });

  test('o job que termina depois do cancelamento não mexe na tela', () async {
    // O job continua no servidor: ele pode estar a um segundo de acabar. O que não pode é
    // ressuscitar uma tela que a pessoa já deixou para trás.
    unawaited(controller().start());
    await pumpEventQueue();

    controller().cancel();
    await watcher.concluir();
    await pumpEventQueue();

    expect(state().running, isFalse);
    expect(state().error, isNull);
    expect(controller().recebeu, isNull);
    expect(controller().recarregou, 0);
  });

  test('depois de cancelar, pedir de novo enfileira de novo', () async {
    // A trava contra o disparo duplo mora no `running` do estado; se cancelar não a soltasse,
    // a tela ficaria inerte até o app ser reiniciado.
    unawaited(controller().start());
    await pumpEventQueue();
    controller().cancel();
    await pumpEventQueue();

    unawaited(controller().start());
    await pumpEventQueue();

    expect(controller().enfileirou, 2);
    expect(state().running, isTrue);
  });

  test('o caminho feliz continua entregando o resultado', () async {
    unawaited(controller().start());
    await pumpEventQueue();
    await watcher.concluir();
    await pumpEventQueue();

    expect(controller().recebeu?.succeeded, isTrue);
    expect(controller().recarregou, 1);
    expect(state().running, isFalse);
    expect(state().error, isNull);
  });

  // A cota do dia é a única recusa desta base que tem uma saída a oferecer, e é aqui que ela
  // se separa das outras. A separação é por status e não pelo texto: a frase vem pronta do
  // servidor, e procurar "Assine o Pro" dentro dela quebraria na primeira reescrita lá.
  test('o 429 marca cota atingida e preserva a frase do servidor', () async {
    controller().recusa = ApiException(
      'Limite diário de 10 análises de refeição atingido. Assine o Pro para '
      'ampliar.',
      statusCode: 429,
    );

    await controller().start();

    expect(state().limitReached, isTrue);
    expect(
      state().error,
      contains('Assine o Pro'),
      reason: 'quem sabe o limite configurado no ambiente é o servidor',
    );
    expect(state().running, isFalse);
  });

  test('a falha do servidor não vira oferta de assinatura', () async {
    controller().recusa = ApiException(
      'O servidor falhou. Tente de novo em instantes.',
      statusCode: 500,
    );

    await controller().start();

    expect(state().limitReached, isFalse);
    expect(state().error, isNotNull);
  });
}
