import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/jobs/job_status.dart';
import 'package:myotrack/core/jobs/job_watcher.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/coach/coach_controller.dart';
import 'package:myotrack/features/coach/coach_page.dart';
import 'package:myotrack/features/home/today_controller.dart';

import '../home/home_test_harness.dart';

/// O coach é a única tela sem herói — a conversa é a tela. O que estes testes fixam é o que
/// sobra dessa decisão: o bloco só existe enquanto não há conversa, e a régua de dia só aparece
/// quando o dia muda.
void main() {
  const smallPhone = Size(360, 800);
  final agora = DateTime(2026, 8, 4, 15);

  Future<void> pump(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nowProvider.overrideWithValue(() => agora), ...overrides],
        child: MaterialApp(theme: AppTheme.dark(), home: const CoachPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('daySeparator', () {
    CoachMessage em(String iso) => CoachMessage(id: iso, createdAt: iso);

    // A tabela é a razão de a função ser pura: "a segunda mensagem do mesmo dia não repete o
    // rótulo" é o tipo de regra que ninguém confere à mão em cada build.
    test('a primeira mensagem sempre abre um dia', () {
      final messages = [em('2026-08-04T09:00:00')];
      expect(daySeparator(messages, 0, agora), 'Hoje');
    });

    test('mensagem do mesmo dia não repete o rótulo', () {
      final messages = [em('2026-08-04T09:00:00'), em('2026-08-04T09:01:00')];
      expect(daySeparator(messages, 1, agora), isNull);
    });

    test('a virada do dia traz a régua de volta', () {
      final messages = [em('2026-08-03T22:00:00'), em('2026-08-04T07:00:00')];
      expect(daySeparator(messages, 0, agora), 'Ontem');
      expect(daySeparator(messages, 1, agora), 'Hoje');
    });

    test('mais de um dia atrás vira a data', () {
      final messages = [em('2026-07-28T10:00:00')];
      expect(daySeparator(messages, 0, agora), '28 de julho');
    });

    // Mensagem sem data é o que o servidor devolve enquanto a resposta ainda está sendo
    // gravada; ela não pode inventar uma régua.
    test('mensagem sem data não abre dia nenhum', () {
      expect(daySeparator([const CoachMessage(id: 'x')], 0, agora), isNull);
    });
  });

  testWidgets('sem conversa, o bloco diz o que ele sabe e o que ele não é', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.textContaining('não substitui avaliação médica'), findsOne);
    // As sugestões são tocáveis: ler e ter que redigitar seria pedir o trabalho duas vezes.
    expect(find.text('Posso treinar com dor no ombro?'), findsOne);
  });

  testWidgets('com conversa, o bloco some e as réguas de dia aparecem', (
    tester,
  ) async {
    await pump(tester, homeOverrides(coachMessages: conversaComOCoach));

    expect(find.textContaining('não substitui avaliação médica'), findsNothing);
    // A conversa abre no fim: "Hoje" está à vista, e o dia anterior fica acima da dobra — numa
    // lista invertida e preguiçosa, ele ainda nem existe na árvore.
    expect(find.text('Hoje'), findsOne);

    await tester.scrollUntilVisible(
      find.text('Ontem'),
      200,
      // O da conversa, e não "o Scrollable": o campo de escrever tem um só dele, e
      // `find.byType(Scrollable)` acha os dois.
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Ontem'), findsOne);
  });

  testWidgets('enquanto o coach responde, o compositor fica bloqueado', (
    tester,
  ) async {
    await pump(tester, [
      ...homeOverrides(coachMessages: conversaComOCoach),
      coachProvider.overrideWith(_Thinking.new),
    ]);

    expect(find.text('O coach está pensando…'), findsOne);
    // Sem isto, uma segunda pergunta entraria na fila por cima da primeira.
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('a pergunta aparece na hora, sem esperar a resposta', (
    tester,
  ) async {
    // O comportamento que este teste fixa é o da espera, não o do fim dela: entre o toque em
    // enviar e a resposta do modelo passam de dez a quarenta segundos, e antes disto a
    // conversa não registrava nada do que a pessoa tinha acabado de dizer.
    final conversa = <CoachMessage>[];
    final watcher = _FakeWatcher();

    await pump(tester, [
      ...homeOverrides(coachMessages: conversa),
      coachRepositoryProvider.overrideWith(
        (ref) => _FakeCoachRepository(conversa),
      ),
      jobWatcherProvider.overrideWithValue(watcher),
    ]);

    await tester.enterText(find.byType(TextField), 'Posso treinar hoje?');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    // O servidor não devolveu mensagem nenhuma, e o balão já está na tela.
    expect(conversa, isEmpty);
    expect(find.text('Posso treinar hoje?'), findsOne);

    // E ele não vira um segundo balão quando o verdadeiro chega.
    conversa.addAll(const [
      CoachMessage(
        id: 'm1',
        fromUser: true,
        content: 'Posso treinar hoje?',
        createdAt: '2026-08-04T15:00:00',
      ),
      CoachMessage(
        id: 'm2',
        content: 'Pode: seu treino B é hoje.',
        createdAt: '2026-08-04T15:00:20',
      ),
    ]);
    await watcher.finish();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Posso treinar hoje?'), findsOne);
    expect(find.text('Pode: seu treino B é hoje.'), findsOne);
  });

  testWidgets('a espera troca de frase em vez de ficar parada', (tester) async {
    await pump(tester, [
      ...homeOverrides(coachMessages: conversaComOCoach),
      coachProvider.overrideWith(_Working.new),
    ]);

    // Nunca `pumpAndSettle` daqui para baixo: os pontos pulsam para sempre, e a espera
    // nunca assenta — é esse o ponto deles.
    expect(find.text('O coach está pensando…'), findsOne);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Lendo seu perfil…'), findsOne);
    expect(find.text('O coach está pensando…'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Abrindo seu plano de treino…'), findsOne);
  });

  testWidgets('na fila, a narração não inventa trabalho que ninguém começou', (
    tester,
  ) async {
    // "Lendo seu perfil…" enquanto o job espera na fila seria mentira: o worker nem pegou o
    // job ainda. O que o servidor diz tem precedência sobre a narração.
    await pump(tester, [
      ...homeOverrides(coachMessages: conversaComOCoach),
      coachProvider.overrideWith(_Queued.new),
    ]);

    await tester.pump(const Duration(seconds: 12));

    expect(find.text('Na fila…'), findsOne);
    expect(find.text('Lendo seu perfil…'), findsNothing);
  });

  /// O que a divisão em conversas trouxe: qual delas abre, como se troca, e o que acontece
  /// com o que foi dito quando uma some.
  group('conversas', () {
    Future<void> comHistorico(
      WidgetTester tester, [
      List<Override> extra = const [],
    ]) async {
      await pump(tester, [
        ...homeOverrides(
          coachMessages: conversaComOCoach,
          coachConversations: conversasComOCoach,
        ),
        ...extra,
      ]);
      await tester.pumpAndSettle();
    }

    testWidgets('abre na mais recente, e a barra diz qual é', (tester) async {
      // Abrir numa tela em branco esconderia a conversa de ontem atrás de um botão — e é
      // justamente a continuidade que faz o coach parecer alguém que acompanha o treino.
      await comHistorico(tester);

      expect(find.text('Dor no ombro no supino'), findsOne);
      // A última resposta dela, e não a pergunta: as perguntas de exemplo do convite usam o
      // mesmo texto, e o teste passaria com a tela mostrando o convite.
      expect(find.textContaining('72,5 kg'), findsOne);
    });

    testWidgets('o histórico lista as conversas e marca a aberta', (
      tester,
    ) async {
      await comHistorico(tester);
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('Ceia antes de dormir'), findsOne);
      // Quando ela parou e o tamanho dela: nenhuma das duas basta sozinha.
      expect(find.text('Hoje · 4 mensagens'), findsOne);
      expect(find.text('1 de agosto · 6 mensagens'), findsOne);
      // O tique diz qual das linhas é a que está por baixo da folha.
      expect(find.byIcon(Icons.check_circle_outline), findsOne);
    });

    testWidgets('escolher outra conversa troca a que está na tela', (
      tester,
    ) async {
      await comHistorico(tester);
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ceia antes de dormir'));
      await tester.pumpAndSettle();

      expect(find.text('Ceia antes de dormir'), findsOne);
      expect(find.textContaining('72,5 kg'), findsNothing);
    });

    testWidgets('nova conversa devolve o convite', (tester) async {
      await comHistorico(tester);
      await tester.tap(find.byIcon(Icons.add_comment_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('não substitui avaliação médica'), findsOne);
      expect(find.text('Dor no ombro no supino'), findsNothing);
    });

    testWidgets('apagar pergunta antes, porque não há desfazer', (
      tester,
    ) async {
      final repository = _FakeCoachRepository(
        conversaComOCoach,
        conversas: conversasComOCoach,
      );
      await comHistorico(tester, [
        coachRepositoryProvider.overrideWith((ref) => repository),
      ]);

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.apagadas, isEmpty);

      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      expect(repository.apagadas, ['conv-3']);
    });
  });
}

/// O coach no meio de uma resposta.
class _Thinking extends CoachController {
  @override
  GenerationState build() =>
      const GenerationState(running: true, step: 'O coach está pensando…');
}

/// O worker já pegou o job — é a fase em que a narração roda.
class _Working extends CoachController {
  @override
  GenerationState build() => const GenerationState(
    running: true,
    step: 'O coach está pensando…',
    phase: JobState.processing,
  );
}

/// O job enfileirado, com ninguém trabalhando nele ainda.
class _Queued extends CoachController {
  @override
  GenerationState build() => const GenerationState(
    running: true,
    step: 'Na fila…',
    phase: JobState.pending,
  );
}

/// Um job que só anda quando o teste manda.
///
/// A espera do coach é o assunto de metade destes testes, e ela é justamente o intervalo em
/// que o servidor ainda não respondeu — sem controlar o relógio do job não há como parar ali.
class _FakeWatcher implements JobWatcher {
  final _events = StreamController<JobStatus>();

  // O prazo é ignorado de propósito: quem decide quando este job anda é o teste, e um
  // relógio real aqui faria a espera terminar sozinha no meio da verificação.
  @override
  Stream<JobStatus> watch(
    String jobId, {
    Duration within = JobWatcher.maxWait,
  }) => _events.stream;

  @override
  Future<JobStatus> await_(
    String jobId, {
    Duration within = JobWatcher.maxWait,
  }) => watch(jobId).last;

  void emit(JobState state) =>
      _events.add(JobStatus(id: 'job-1', type: 'CoachChat', state: state));

  Future<void> finish() async {
    emit(JobState.completed);
    await _events.close();
  }
}

class _FakeCoachRepository implements CoachRepository {
  _FakeCoachRepository(this.conversa, {this.conversas = const []});

  /// A mesma lista que o override de `coachMessagesProvider` devolve: mutá-la é o que
  /// simula o servidor tendo gravado a pergunta e a resposta.
  final List<CoachMessage> conversa;

  final List<CoachConversation> conversas;

  /// O que foi apagado, na ordem em que foi.
  final apagadas = <String>[];

  @override
  Future<List<CoachConversation>> conversations() async => conversas;

  @override
  Future<List<CoachMessage>> messages(String conversationId) async => conversa;

  @override
  Future<SentQuestion> send(String content, {String? conversationId}) async => (
    jobId: 'job-1',
    // Sem conversa, o servidor abre uma e devolve o id dela — é assim que a tela descobre
    // em qual conversa a pergunta caiu.
    conversationId: conversationId ?? 'conv-nova',
  );

  @override
  Future<void> remove(String conversationId) async =>
      apagadas.add(conversationId);
}
