import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state.dart';
import 'coach_controller.dart';

/// Chat com o coach de IA.
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
  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);
    final messagesAsync = ref.watch(coachMessagesProvider);

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
                  ? const _FirstMessage()
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        Space.gutter,
                        12,
                        Space.gutter,
                        12,
                      ),
                      children: [
                        for (final message in messages)
                          _Bubble(message: message),
                        if (state.running) _Typing(step: state.step),
                      ],
                    ),
            ),
          ),
          _Composer(controller: _input, enabled: !state.running, onSend: _send),
        ],
      ),
    );
  }
}

/// Primeira vez: sugere o que perguntar.
///
/// Um campo de texto vazio diante de "converse com o coach" trava a maioria das pessoas —
/// exemplos concretos mostram o que ele sabe responder.
class _FirstMessage extends ConsumerWidget {
  const _FirstMessage();

  static const _suggestions = [
    'Como está minha evolução no supino?',
    'Posso treinar com dor no ombro?',
    'O que comer depois do treino?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: 48,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'Converse com seu coach',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Ele conhece seu perfil, seus planos e seus últimos treinos.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        for (final suggestion in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => ref.read(coachProvider.notifier).ask(suggestion),
              child: Text(suggestion, textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = message.fromUser;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          // Balão nunca ocupa a largura toda: sem o teto, uma resposta longa vira um bloco
          // de texto e a conversa perde a forma de conversa.
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mine ? theme.colorScheme.onPrimaryContainer : null,
          ),
        ),
      ),
    );
  }
}

/// O coach pensando. Fica no lugar onde a resposta vai aparecer, para a espera ter endereço.
class _Typing extends StatelessWidget {
  const _Typing({required this.step});

  final String? step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              step ?? 'O coach está pensando…',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
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
                  // O contador só atrapalha numa pergunta de dez palavras.
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
              tooltip: 'Enviar',
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
