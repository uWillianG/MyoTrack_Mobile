import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: sem ele o "Hoje" que separa um dia do outro na conversa mudaria
// de valor entre a captura da galeria e a execução do teste.
import '../home/today_controller.dart' show nowProvider;
import 'coach_controller.dart';

/// O rótulo de dia a mostrar **antes** da mensagem [index], ou null quando ela é do mesmo dia
/// da anterior.
///
/// Uma conversa com o coach dura meses e é lida de baixo para cima. Sem a separação, a resposta
/// de três semanas atrás encosta na pergunta de hoje e parece parte da mesma conversa — que é
/// como um conselho antigo volta a ser lido como atual.
///
/// Função pura e no topo do arquivo porque é a única decisão de produto desta tela, e decisão
/// de produto se testa por tabela.
String? daySeparator(List<CoachMessage> messages, int index, DateTime now) {
  final at = _at(messages[index]);
  if (at == null) {
    return null;
  }
  if (index > 0) {
    final previous = _at(messages[index - 1]);
    if (previous != null && Fmt.sameDay(previous, at)) {
      return null;
    }
  }

  return Fmt.dayLabel(at, now);
}

DateTime? _at(CoachMessage message) => message.createdAt == null
    ? null
    : DateTime.tryParse(message.createdAt!)?.toLocal();

/// Chat com o coach de IA.
///
/// **A única tela convertida sem herói, e é de propósito.** O bloco de cor cheia é para telas
/// que se consultam: ele promove um assunto entre vários. Numa conversa não há vários — a
/// conversa é a tela inteira, e um bloco no topo tomaria o espaço das mensagens para repetir o
/// que a barra de título já diz.
///
/// O bloco aparece num caso só: enquanto **não há** conversa. Aí ele é o que a tela tem, e some
/// para sempre na primeira pergunta.
///
/// **Sem família de cor.** O coach fala de treino, de dieta e de constância; pintá-lo de
/// esmeralda ou de índigo diria que ele pertence a um desses assuntos. Neutro, como manda o §4
/// para o que não é assunto — e o único bloco saturado da tela passa a ser **o que você disse**.
class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (!await ref.read(coachProvider.notifier).ask(text)) {
      return;
    }
    // Limpa só depois de aceitar: se a pergunta foi recusada (vazia, ou outra em curso), o
    // texto continua ali para a pessoa não ter que redigitar.
    _input.clear();
    _toBottom();
  }

  /// Rola para a última mensagem depois que o quadro é desenhado.
  ///
  /// Zero e não `maxScrollExtent`: a lista é invertida, e nela o fim da conversa é a origem
  /// da rolagem.
  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: Motion.base, curve: Motion.enter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);
    final messagesAsync = ref.watch(coachMessagesProvider);
    final colors = Blocks.neutral(Theme.of(context).colorScheme);

    ref.listen(coachProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(coachProvider.notifier).dismissError();
      }
      // Resposta chegou: a lista cresceu e a última mensagem precisa ficar visível.
      if (previous?.running == true && !next.running) {
        _toBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível carregar a conversa.',
                detail: '$error',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(coachMessagesProvider),
                  child: const Text('Tentar de novo'),
                ),
              ),
              data: (messages) => messages.isEmpty && !state.running
                  ? _Intro(
                      colors: colors,
                      onAsk: (question) =>
                          ref.read(coachProvider.notifier).ask(question),
                    )
                  : _Conversation(
                      messages: messages,
                      colors: colors,
                      controller: _scroll,
                      now: ref.read(nowProvider)(),
                      typing: state.running ? state.step : null,
                    ),
            ),
          ),
          _Composer(
            controller: _input,
            colors: colors,
            enabled: !state.running,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.messages,
    required this.colors,
    required this.controller,
    required this.now,
    required this.typing,
  });

  final List<CoachMessage> messages;
  final BlockColors colors;
  final ScrollController controller;
  final DateTime now;

  /// A etapa em curso, ou null quando o coach não está respondendo.
  final String? typing;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      // **Invertida.** Numa conversa de três mensagens, a lista normal encosta tudo no topo e
      // deixa meia tela de vazio entre a última resposta e o campo de escrever — como se a
      // conversa tivesse acabado e o resto fosse outra coisa. Invertida, ela se apoia no
      // compositor, e mensagem nova entra sem mexer na posição de rolagem.
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.gutter,
        vertical: Space.sm,
      ),
      children: [
        // Nesta lista, "depois" significa "acima": os filhos são empilhados de baixo para
        // cima. Daí a conversa vir do fim para o começo, e a régua do dia sair **depois** da
        // primeira mensagem dele.
        if (typing != null) _Typing(step: typing, colors: colors),
        for (var i = messages.length - 1; i >= 0; i--) ...[
          _Bubble(message: messages[i], colors: colors),
          if (daySeparator(messages, i, now) case final label?)
            _DayLabel(label: label),
        ],
      ],
    );
  }
}

/// A régua entre um dia e outro.
class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

/// Primeira vez: o que o coach sabe, e o que perguntar.
///
/// **Um campo de texto vazio diante de "converse com o coach" trava a maioria das pessoas.** Os
/// exemplos não são enfeite — são o que mostra o alcance do que ele responde, e por isso são
/// tocáveis: ler a sugestão e ter que redigitá-la seria pedir o trabalho duas vezes.
class _Intro extends StatelessWidget {
  const _Intro({required this.colors, required this.onAsk});

  final BlockColors colors;
  final ValueChanged<String> onAsk;

  static const _suggestions = [
    (icon: Icons.trending_up, question: 'Como está minha evolução no supino?'),
    (icon: Icons.healing_outlined, question: 'Posso treinar com dor no ombro?'),
    (
      icon: Icons.restaurant_outlined,
      question: 'O que comer depois do treino?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.xs,
        Space.gutter,
        Space.xxl,
      ),
      children: [
        HeroBlock(
          colors: colors,
          label: 'Coach',
          icon: Icons.forum_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O que você\nquer saber?',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onTone,
                ),
              ),
              const SizedBox(height: Space.sm),
              // O que ele sabe **e** o que ele não é. A segunda sugestão desta mesma tela
              // pergunta sobre dor no ombro: sem esta linha, a resposta de um modelo passa a
              // ser lida como avaliação clínica.
              Text(
                'Ele conhece seu perfil, seus planos e seus últimos treinos — e não substitui '
                'avaliação médica.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onTone.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        BlockSection(
          colors: colors,
          label: 'Para começar',
          icon: Icons.bolt_outlined,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _suggestions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: Space.md,
                    endIndent: Space.md,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ListTile(
                  leading: Icon(_suggestions[i].icon, size: 20),
                  title: Text(_suggestions[i].question),
                  trailing: const Icon(Icons.north_east, size: 16),
                  onTap: () => onAsk(_suggestions[i].question),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma mensagem da conversa.
///
/// **O balão cheio é o seu, e é a única coisa saturada da tela.** Numa conversa quem escreve não
/// é um assunto, e por isso nenhuma das quatro famílias serve — o destaque sai do neutro, que
/// no escuro é claro e no claro é escuro. O do coach é lavado: ele fala muito mais, e um mural
/// de balões cheios cansaria antes da terceira resposta.
///
/// Foi este balão que expôs o lavado neutro fraco do tema claro: uma seção tem rótulo e ícone
/// ancorando a forma, um balão não tem nada, e ali o defeito ficou impossível de ignorar. A
/// correção foi na fonte, em [Blocks.neutral], e não aqui.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.colors});

  final CoachMessage message;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = message.fromUser;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md - 2,
          vertical: Space.sm - 2,
        ),
        constraints: BoxConstraints(
          // Balão nunca ocupa a largura toda: sem o teto, uma resposta longa vira um bloco
          // de texto e a conversa perde a forma de conversa.
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? colors.tone : colors.wash,
          // O canto vivo aponta para quem falou — é o que dá direção ao balão sem precisar de
          // um bico desenhado, que em tela pequena vira sujeira.
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.md),
            topRight: const Radius.circular(Radii.md),
            bottomLeft: Radius.circular(mine ? Radii.md : 6),
            bottomRight: Radius.circular(mine ? 6 : Radii.md),
          ),
        ),
        child: Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mine ? colors.onTone : null,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

/// O coach pensando. Fica no lugar onde a resposta vai aparecer, para a espera ter endereço.
class _Typing extends StatelessWidget {
  const _Typing({required this.step, required this.colors});

  final String? step;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md - 2,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: colors.wash,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Radii.md),
            topRight: Radius.circular(Radii.md),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(Radii.md),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Space.sm - 2),
            Flexible(
              child: Text(
                step ?? 'O coach está pensando…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onde a pergunta é escrita.
///
/// O campo vira uma faixa arredondada do mesmo tom dos balões do coach, e o enviar é um círculo
/// da cor do **seu** balão: o botão que cria a sua mensagem tem a cor dela.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.colors,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final BlockColors colors;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.sm,
          Space.xxs,
          Space.sm,
          Space.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Material(
                color: colors.wash,
                borderRadius: Radii.lgAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.xxs,
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    // Pergunta costuma ser uma frase, mas cabe mais: o servidor aceita até
                    // 2000 caracteres.
                    maxLines: 4,
                    minLines: 1,
                    maxLength: 2000,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: enabled
                          ? 'Pergunte ao coach…'
                          : 'Aguarde a resposta…',
                      isDense: true,
                      // Sem moldura: quem delimita o campo é a faixa lavada em volta dele, e
                      // uma borda por dentro de outra é caixa dentro de caixa.
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: Space.sm,
                      ),
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      // O contador só atrapalha numa pergunta de dez palavras.
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.arrow_upward, size: 20),
              tooltip: 'Enviar',
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                backgroundColor: colors.tone,
                foregroundColor: colors.onTone,
                disabledBackgroundColor: colors.wash,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
