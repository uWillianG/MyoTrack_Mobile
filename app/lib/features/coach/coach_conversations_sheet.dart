import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
// O relógio do app, injetável: sem ele o "Hoje" desta lista mudaria de valor entre a captura
// da galeria e a execução do teste.
import '../home/today_controller.dart' show nowProvider;
import 'coach_controller.dart';

/// O histórico de conversas com o coach.
///
/// **Uma folha, e não uma tela.** A lista existe para sair dela: quem a abre quer voltar a um
/// assunto, e uma tela empilhada obrigaria a um segundo toque para desfazer um toque errado.
/// Ela também é o lugar do "nova conversa" — o botão que começa um assunto pertence à lista de
/// assuntos, e não à barra de uma conversa em curso.
Future<void> showCoachConversationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável: um ano de uso são dezenas de conversas, e a folha precisa poder crescer até
    // meia tela sem cortar a última linha.
    isScrollControlled: true,
    builder: (_) => const CoachConversationsSheet(),
  );
}

class CoachConversationsSheet extends ConsumerWidget {
  const CoachConversationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final conversations = ref.watch(coachConversationsProvider);
    final open = ref.watch(openConversationProvider);
    final busy = ref.watch(coachProvider).running;
    final now = ref.read(nowProvider)();

    return SafeArea(
      child: ConstrainedBox(
        // Teto de altura: sem ele a folha de quem tem uma conversa só nasce com o tamanho de
        // duas linhas, e a de quem tem quarenta cobre a tela inteira.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('Nova conversa'),
              subtitle: const Text('Começa um assunto do zero'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(openConversationProvider.notifier).open(null);
              },
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Flexible(
              child: conversations.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(Space.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(Space.gutter),
                  child: Text(
                    'Não foi possível carregar suas conversas.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                data: (all) => all.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(Space.gutter),
                        child: Text(
                          'Suas conversas ficam aqui. A primeira pergunta abre a primeira.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: Space.xs),
                        itemCount: all.length,
                        itemBuilder: (context, i) => _ConversationTile(
                          conversation: all[i],
                          now: now,
                          isOpen: all[i].id == open,
                          busy: busy,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma conversa na lista: o assunto, quando ela parou, e a saída para apagá-la.
class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.now,
    required this.isOpen,
    required this.busy,
  });

  final CoachConversation conversation;
  final DateTime now;

  /// A conversa que já está na tela por trás da folha.
  final bool isOpen;

  /// True enquanto o coach responde. Apagar aí dentro deixaria uma resposta a caminho de uma
  /// conversa que não existe mais.
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      selected: isOpen,
      // O tique marca onde a pessoa está. Sem ele, a folha aberta sobre uma conversa não diz
      // qual das linhas é a que está por baixo dela.
      leading: Icon(
        isOpen ? Icons.check_circle_outline : Icons.forum_outlined,
        color: isOpen ? theme.colorScheme.primary : null,
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_subtitle(), maxLines: 1, overflow: TextOverflow.ellipsis),
      // Miúdo e apagado de propósito: o que se faz nesta folha é **escolher** uma conversa, e
      // três lixeiras em coluna com o mesmo peso dos títulos fariam a lista parecer uma tela
      // de limpeza. A afordância continua ali para quem a procura.
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        color: theme.colorScheme.onSurfaceVariant,
        tooltip: 'Apagar conversa',
        onPressed: busy ? null : () => _confirmDelete(context, ref),
      ),
      onTap: () {
        Navigator.of(context).pop();
        ref.read(openConversationProvider.notifier).open(conversation.id);
      },
    );
  }

  /// "Ontem · 6 mensagens" — quando ela parou, e o tamanho dela.
  ///
  /// As duas coisas juntas porque nenhuma basta: a data sozinha não distingue a pergunta solta
  /// da conversa em que se voltou três vezes, e a contagem sozinha não diz se ela é de ontem
  /// ou de março.
  String _subtitle() {
    final at = conversation.updatedAt == null
        ? null
        : DateTime.tryParse(conversation.updatedAt!)?.toLocal();
    final size = conversation.messages == 1
        ? '1 mensagem'
        : '${conversation.messages} mensagens';

    return at == null ? size : '${Fmt.dayLabel(at, now)} · $size';
  }

  /// Pergunta antes de apagar.
  ///
  /// **Não há desfazer, e não há cópia.** A conversa mora só no servidor: apagada, a única
  /// pessoa que ainda sabe o que o coach respondeu é quem leu na hora.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar esta conversa?'),
        content: Text(
          'As mensagens de "${conversation.title}" somem para sempre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    // A folha continua aberta: quem apaga costuma apagar mais de uma, e fechá-la obrigaria a
    // reabrir a lista a cada linha. O erro, quando houver, sai no snackbar da tela de trás.
    await ref.read(coachProvider.notifier).remove(conversation.id);
  }
}
