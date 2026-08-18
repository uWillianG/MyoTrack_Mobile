import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/materials.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/jobs/job_status.dart';
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

  void _send() {
    if (!ref.read(coachProvider.notifier).ask(_input.text)) {
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
                      typing: state.running,
                      step: state.step,
                      phase: state.phase,
                      // O balão otimista. `watch` no estado logo acima é o que traz o
                      // rebuild; o notifier em si não muda de instância.
                      pending: ref.watch(coachProvider.notifier).pending,
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
    required this.step,
    required this.phase,
    required this.pending,
  });

  final List<CoachMessage> messages;
  final BlockColors colors;
  final ScrollController controller;
  final DateTime now;

  /// True enquanto o coach está respondendo.
  final bool typing;

  /// O rótulo que veio do servidor, e a fase crua por trás dele.
  final String? step;
  final JobState? phase;

  /// A pergunta já enviada e ainda ausente de [messages] — desenhada como balão comum, no
  /// lugar que ela vai ocupar quando a lista voltar do servidor.
  final String? pending;

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
        if (typing) _Typing(step: step, phase: phase, colors: colors),
        if (pending case final question?)
          _Bubble(
            // Id de mentira e sem data: ele nunca é comparado com nada, e a régua de dia só
            // olha as mensagens que vieram do servidor.
            message: CoachMessage(
              id: 'pendente',
              fromUser: true,
              content: question,
            ),
            colors: colors,
          ),
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
                  color: colors.onGlass,
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
                  color: colors.onGlass.withValues(alpha: 0.85),
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
/// O coach trabalhando: três pontos que não param e uma frase que troca.
///
/// **Por que o rodinha com um rótulo fixo não bastava.** A resposta leva de dez a quarenta
/// segundos — é uma chamada de LLM com perfil, planos, sessões recentes e a transcrição no
/// contexto —, e uma frase parada esse tempo todo é indistinguível de um app travado. Quem
/// espera não tem como saber se a resposta ainda está vindo.
///
/// **A narração não é enfeite inventado.** É a ordem em que o worker monta o contexto antes de
/// chamar o modelo (`CoachChatHandler.handle`): perfil, plano de treino, sessões, dieta,
/// conversa. O que ela não é — e não finge ser — é um traço ao vivo: o servidor só informa
/// três fases. Por isso **o que ele diz tem precedência**: o rótulo verdadeiro abre a
/// sequência, a narração só entra depois que o worker de fato pegou o job, e qualquer notícia
/// nova do servidor recomeça tudo.
///
/// **Ela para na última frase em vez de voltar ao começo.** Reexibir "Lendo seu perfil…"
/// depois de "Escrevendo a resposta…" leria como trabalho refeito. Numa espera longa, quem
/// sustenta a sensação de vivo são os pontos — e eles não param.
class _Typing extends StatefulWidget {
  const _Typing({
    required this.step,
    required this.phase,
    required this.colors,
  });

  final String? step;
  final JobState? phase;
  final BlockColors colors;

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  /// O que o worker faz antes de chamar o modelo, na ordem em que ele faz.
  static const _narration = [
    'Lendo seu perfil…',
    'Abrindo seu plano de treino…',
    'Conferindo seus últimos treinos…',
    'Olhando sua dieta…',
    'Relendo a conversa…',
    'Escrevendo a resposta…',
  ];

  /// Quanto cada frase fica na tela. Abaixo de uns três segundos a troca vira pisca-pisca e
  /// ninguém termina de ler a anterior.
  static const _dwell = Duration(seconds: 3);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  Timer? _clock;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(_Typing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O servidor deu notícia: o que ele diz volta a ser o que está escrito, e a narração
    // recomeça a partir dali.
    if (oldWidget.step != widget.step || oldWidget.phase != widget.phase) {
      _restart();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _restart() {
    _clock?.cancel();
    _index = 0;

    if (_labels.length < 2) {
      return;
    }
    _clock = Timer.periodic(_dwell, (timer) {
      if (_index >= _labels.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _index++);
    });
  }

  /// O rótulo verdadeiro na frente; a narração atrás dele, e só quando há o que narrar.
  List<String> get _labels => [
    widget.step ?? 'O coach está pensando…',
    if (widget.phase == JobState.processing) ..._narration,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = _labels;
    final label = labels[_index.clamp(0, labels.length - 1)];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md - 2,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: widget.colors.wash,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Radii.md),
            topRight: Radius.circular(Radii.md),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(Radii.md),
          ),
        ),
        // Frases de larguras diferentes fariam o balão saltar de tamanho a cada três
        // segundos; assim ele acompanha.
        child: AnimatedSize(
          duration: Motion.base,
          curve: Motion.enter,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingDots(
                animation: _pulse,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Space.sm - 2),
              Flexible(
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  switchInCurve: Motion.enter,
                  switchOutCurve: Motion.exit,
                  // A frase nova sobe empurrando a anterior — o gesto de "avançou uma etapa".
                  // Apagar e acender no mesmo lugar leria como correção de um erro.
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Três pontos subindo e descendo em ondas defasadas.
///
/// O rodinha do Material dizia "carregando", que é o que toda tela do app diz enquanto espera
/// alguma coisa. Os pontos dizem outra: que tem alguém do outro lado escrevendo. É a convenção
/// de qualquer aplicativo de conversa, e aqui ela custa três círculos.
class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  static const _count = 3;
  static const _diameter = 6.0;

  /// O quanto o ponto sobe no alto da onda.
  static const _travel = 2.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Altura reservada para o curso inteiro: sem ela o ponto no alto da onda invade o
      // respiro do balão, e a linha de texto ao lado dança junto.
      height: _diameter + _travel * 2,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _count; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              _dot(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    // Cada ponto entra um terço de ciclo depois do anterior: é a defasagem que faz a onda
    // correr da esquerda para a direita em vez de os três piscarem juntos.
    final phase = (animation.value + index / _count) % 1;
    // Seno e não uma rampa: a volta ao início do ciclo precisa ser contínua, senão a cada
    // 1,1 s o ponto salta do alto para o chão.
    final wave = (math.sin(phase * 2 * math.pi) + 1) / 2;

    return Transform.translate(
      offset: Offset(0, -wave * _travel),
      child: Container(
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3 + wave * 0.7),
          shape: BoxShape.circle,
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
              // Vidro, como o resto do app: o campo fica sobre a conversa rolando, e um
              // retângulo chapado ali era a última superfície pintada que sobrou da versão
              // anterior — lia como uma peça colada por cima da tela.
              child: GlassPanel(
                radius: Radii.lgAll,
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
                      // **Nem moldura nem preenchimento.** Quem delimita o campo é o vidro em
                      // volta dele; o `filled` que o tema liga em todo campo do app pintaria
                      // um segundo retângulo por dentro do primeiro — caixa dentro de caixa, e
                      // a de dentro com o raio errado.
                      filled: false,
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
