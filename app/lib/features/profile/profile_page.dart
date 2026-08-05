import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/blocks.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/blocks.dart';
import '../dashboard/dashboard_controller.dart';
import '../home/account_destinations.dart';
import '../reviews/review_controller.dart';
import 'data/profile_models.dart';
import 'onboarding_controller.dart';
import 'widgets/profile_editors.dart';

/// Perfil.
///
/// **Duas telas atrás de um nome só, e é isso que a torna intuitiva.**
///
/// Quem ainda não tem perfil vê o **cadastro**: os cinco grupos de campos numa página, com o
/// consentimento e o botão no fim. Quem já tem vê o **resumo**: o que está salvo, agrupado, e
/// cada grupo abre sozinho numa folha para ser mudado.
///
/// Antes as duas tarefas eram a mesma coisa — um assistente de cinco etapas —, e as duas
/// sofriam com isso. Mudar os dias de treino custava cinco toques: entrar, avançar até a etapa
/// certa, mudar, e avançar até o fim para achar o botão que salva. E a aba chamada "Perfil"
/// **nunca mostrava o perfil**: não havia como responder "o que o app sabe sobre mim?" sem
/// percorrer o assistente inteiro.
///
/// Os campos são os mesmos widgets nos dois modos (`widgets/profile_editors.dart`): quem
/// preencheu "Dias de treino" no cadastro reencontra o mesmo controle, no mesmo lugar dentro do
/// grupo, quando volta meses depois.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.hasProfile ? 'Meu perfil' : 'Criar perfil'),
        automaticallyImplyLeading: state.hasProfile,
      ),
      body: const ProfileView(),
    );
  }
}

/// O perfil sem a barra de título — é o que a aba Perfil hospeda.
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _fields = ProfileFieldControllers();

  /// Os campos de texto só podem ser preenchidos depois que o perfil chega do servidor — e uma
  /// vez só, senão sobrescrevem o que o usuário está digitando.
  bool _seeded = false;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_seeded) {
      _seeded = true;
      _fields.seed(
        state.form,
        lastWeightKg: ref
            .read(dashboardStatsProvider)
            .valueOrNull
            ?.currentWeightKg,
      );
    }

    return state.hasProfile
        ? _Summary(state: state, weightKg: _fields.weight.text)
        : _Setup(state: state, fields: _fields);
  }
}

// ---------------------------------------------------------------------------------------
// Cadastro: uma página, cinco grupos
// ---------------------------------------------------------------------------------------

class _Setup extends ConsumerWidget {
  const _Setup({required this.state, required this.fields});

  final OnboardingState state;
  final ProfileFieldControllers fields;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final form = state.form;
    final controller = ref.read(onboardingControllerProvider.notifier);

    void change(OnboardingForm updated) => controller.update(updated);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        HeroBlock(
          colors: Blocks.workout(brightness),
          label: 'Seu perfil',
          icon: Icons.auto_awesome,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conte quem\nestá treinando.',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Blocks.workout(brightness).onTone,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                'É daqui que sai seu treino e sua meta de calorias. '
                'Sexo, altura e peso são o mínimo — o resto refina o plano.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Blocks.workout(
                    brightness,
                  ).onTone.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        for (final group in _Group.values) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: group.colors(brightness, theme.colorScheme),
            label: group.label,
            icon: group.icon,
            child: group.editor(form, fields, change),
          ),
        ],
        // O consentimento não é negociável: sem ele o app trata dado de saúde sem base legal.
        // Fica no fim, imediatamente antes do botão que salva de verdade — e é ele que
        // justifica o botão ficar no fim da rolagem em vez de preso no rodapé.
        const SizedBox(height: Space.sm),
        _Consent(
          value: form.consented,
          onChanged: (v) => change(form.copyWith(consented: v)),
        ),
        if (state.error case final error?) ...[
          const SizedBox(height: Space.sm),
          _ErrorBanner(message: error),
        ],
        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: state.saving
              ? null
              : () => _save(
                  context,
                  ref,
                  fields.applyTo(form),
                  popOnSuccess: false,
                ),
          child: state.saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar perfil'),
        ),
      ],
    );
  }
}

class _Consent extends StatelessWidget {
  const _Consent({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // `Material` e não `Container`: fundo pintado por `BoxDecoration` fica acima do Material
    // mais próximo e engole o respingo de toque do `CheckboxListTile`.
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: Radii.lgAll,
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgAll),
        title: const Text('Autorizo o tratamento dos meus dados de saúde'),
        subtitle: const Text(
          'Peso, medidas, lesões e histórico de treino são usados para gerar seu '
          'plano. Você pode exportar ou apagar tudo quando quiser.',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Resumo: o que está salvo, e a porta para o resto do app
// ---------------------------------------------------------------------------------------

class _Summary extends ConsumerWidget {
  const _Summary({required this.state, required this.weightKg});

  final OnboardingState state;

  /// A última pesagem conhecida. Vem de fora porque o peso não mora no perfil.
  final String weightKg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final form = state.form;
    final canReview =
        ref.watch(reviewableKindsProvider).valueOrNull?.isNotEmpty ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
      children: [
        HeroBlock(
          colors: Blocks.workout(brightness),
          label: 'Seu plano',
          icon: Icons.flag_outlined,
          child: HeroFigure(
            value: '${form.trainingDaysPerWeek}',
            unit: '× por semana',
            colors: Blocks.workout(brightness),
            detail: [
              _labelOf(ProfileOptions.goals, form.goal),
              _labelOf(ProfileOptions.experienceLevels, form.experienceLevel),
            ].whereType<String>().join(' · '),
          ),
        ),
        for (final group in _Group.values) ...[
          const SizedBox(height: Space.sm),
          BlockSection(
            colors: group.colors(brightness, theme.colorScheme),
            label: group.label,
            icon: group.icon,
            onEdit: () => _openGroup(context, group),
            child: _SummaryLines(
              lines: group.summary(form, weightKg: weightKg),
            ),
          ),
        ],
        const SizedBox(height: Space.xl),
        // A gaveta do avatar, aqui também. Perfil é onde a pessoa **procura** conta,
        // assinatura e configuração; o avatar da Hoje é o atalho de quem já está no meio de
        // outra coisa. A lista vem de um lugar só para as duas nunca divergirem.
        _Destinations(
          destinations: [
            ...accountDestinations,
            if (canReview) reviewDestination,
          ],
        ),
      ],
    );
  }
}

class _SummaryLines extends StatelessWidget {
  const _SummaryLines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
            child: Text(
              lines[i],
              style: i == 0
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Destinations extends StatelessWidget {
  const _Destinations({required this.destinations});

  final List<AccountDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlockSection(
      colors: Blocks.neutral(scheme),
      label: 'O resto do app',
      icon: Icons.apps,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < destinations.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: Space.md,
                endIndent: Space.md,
                color: scheme.outlineVariant,
              ),
            ListTile(
              leading: Icon(destinations[i].icon),
              title: Text(destinations[i].title),
              subtitle: Text(destinations[i].subtitle),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push(destinations[i].route),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Os cinco grupos
// ---------------------------------------------------------------------------------------

/// Um grupo de campos do perfil.
///
/// **Só dois grupos têm cor, e é de propósito.** Treino é índigo e Alimentação é esmeralda
/// porque essas duas famílias já significam alguma coisa no app inteiro — quem usou a Hoje as
/// reconhece antes de ler o rótulo. Você, Equipamento e Lesões ficam neutros.
///
/// A primeira tentativa deu uma família a cada grupo e errou duas vezes. Saíram quatro blocos
/// índigo seguidos, porque equipamento e lesões também alimentam o treino — ritmo de tela
/// nenhum. E "Você" ficou em âmbar, que no resto do app significa **progresso**: cor que muda
/// de significado entre telas não é sistema, é decoração.
enum _Group { you, training, equipment, injuries, food }

extension _GroupX on _Group {
  String get label => switch (this) {
    _Group.you => 'Você',
    _Group.training => 'Treino',
    _Group.equipment => 'Equipamento',
    _Group.injuries => 'Lesões',
    _Group.food => 'Alimentação',
  };

  IconData get icon => switch (this) {
    _Group.you => Icons.person_outline,
    _Group.training => Icons.fitness_center,
    _Group.equipment => Icons.handyman_outlined,
    _Group.injuries => Icons.healing_outlined,
    _Group.food => Icons.restaurant,
  };

  BlockColors colors(Brightness brightness, ColorScheme scheme) =>
      switch (this) {
        _Group.training => Blocks.workout(brightness),
        _Group.food => Blocks.nutrition(brightness),
        _Group.you ||
        _Group.equipment ||
        _Group.injuries => Blocks.neutral(scheme),
      };

  Widget editor(
    OnboardingForm form,
    ProfileFieldControllers fields,
    FormChanged onChanged,
  ) => switch (this) {
    _Group.you => YouEditor(form: form, fields: fields, onChanged: onChanged),
    _Group.training => TrainingEditor(form: form, onChanged: onChanged),
    _Group.equipment => EquipmentEditor(form: form, onChanged: onChanged),
    _Group.injuries => InjuriesEditor(
      form: form,
      fields: fields,
      onChanged: onChanged,
    ),
    _Group.food => FoodEditor(fields: fields),
  };

  /// O que o grupo diz quando está fechado. A primeira linha é a que resume; as demais
  /// detalham.
  ///
  /// **Grupo vazio diz o que a ausência significa**, e não fica em branco: "Academia completa"
  /// é o efeito de não marcar equipamento nenhum, e é isso que a pessoa precisa saber para
  /// decidir se quer mexer.
  List<String> summary(
    OnboardingForm form, {
    String? weightKg,
  }) => switch (this) {
    _Group.you => [
      [
        _labelOf(ProfileOptions.sexes, form.sex),
        _labelOf(ProfileOptions.biotypes, form.biotype),
      ].whereType<String>().join(' · '),
      [
        if (form.heightCm.isNotEmpty) '${form.heightCm} cm',
        // O peso não mora no perfil; quem o conhece é o histórico de medidas. Sem esta
        // linha o resumo omitiria um número que o app tem.
        if (weightKg != null && weightKg.isNotEmpty) '$weightKg kg',
        if (form.birthDate case final date?) '${_ageOf(date)} anos',
      ].join(' · '),
    ].where((l) => l.isNotEmpty).toList(),

    _Group.training => [
      [
        _labelOf(ProfileOptions.experienceLevels, form.experienceLevel),
        _labelOf(ProfileOptions.goals, form.goal),
      ].whereType<String>().join(' · '),
      splitHint(form.trainingDaysPerWeek),
      if (form.priorityMuscleGroups.isNotEmpty)
        'Prioriza ${_labelsOf(ProfileOptions.muscleGroups, form.priorityMuscleGroups)}',
    ],

    _Group.equipment => [
      form.availableEquipment.isEmpty
          ? 'Academia completa'
          : _labelsOf(ProfileOptions.equipment, form.availableEquipment),
      if (form.availableEquipment.isEmpty)
        'Nada marcado: o treino pode usar qualquer aparelho',
    ],

    _Group.injuries => [
      form.injuryTags.isEmpty
          ? 'Nenhuma área sensível'
          : _labelsOf(ProfileOptions.injuries, form.injuryTags),
      if (form.injuryNotes.trim().isNotEmpty) form.injuryNotes.trim(),
    ],

    _Group.food => [
      form.dietaryRestrictions.trim().isEmpty
          ? 'Sem restrições'
          : 'Evita ${form.dietaryRestrictions.trim()}',
      if (form.foodPreferences.trim().isNotEmpty)
        'Prefere ${form.foodPreferences.trim()}',
    ],
  };
}

String? _labelOf(List<Option> options, String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final option in options) {
    if (option.value == value) {
      return option.label;
    }
  }
  // Valor novo no servidor aparece cru em vez de sumir da tela.
  return value;
}

String _labelsOf(List<Option> options, List<String> values) =>
    values.map((v) => _labelOf(options, v)).whereType<String>().join(' · ');

int _ageOf(DateTime birth) {
  final now = DateTime.now();
  var age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age;
}

// ---------------------------------------------------------------------------------------
// A folha de edição de um grupo
// ---------------------------------------------------------------------------------------

Future<void> _openGroup(BuildContext context, _Group group) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável e sem teto fixo: "Treino" tem quatro controles e passa da metade da tela num
    // celular pequeno, e com o teclado aberto o campo de texto do grupo de lesões ficaria
    // debaixo dele.
    isScrollControlled: true,
    builder: (_) => _GroupSheet(group: group),
  );
}

class _GroupSheet extends ConsumerStatefulWidget {
  const _GroupSheet({required this.group});

  final _Group group;

  @override
  ConsumerState<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends ConsumerState<_GroupSheet> {
  /// A folha edita um **rascunho**, e não o formulário do controller.
  ///
  /// Sem isto, cada toque num chip já aparecia no resumo atrás da folha — e fechar sem salvar
  /// deixava a tela mostrando um valor que o servidor não tem. O rascunho só vira verdade no
  /// "Salvar"; até lá, o que está atrás continua sendo o perfil de verdade.
  late OnboardingForm _draft;

  /// Pelo mesmo motivo, os campos de texto são os da folha.
  final _fields = ProfileFieldControllers();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(onboardingControllerProvider).form;
    _fields.seed(
      _draft,
      lastWeightKg: ref
          .read(dashboardStatsProvider)
          .valueOrNull
          ?.currentWeightKg,
    );
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingControllerProvider);

    return SafeArea(
      child: Padding(
        // O teclado empurra a folha em vez de cobri-la.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    widget.group.icon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.xs),
                  Text(widget.group.label, style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: Space.lg),
              widget.group.editor(
                _draft,
                _fields,
                (updated) => setState(() => _draft = updated),
              ),
              if (state.error case final error?) ...[
                const SizedBox(height: Space.md),
                _ErrorBanner(message: error),
              ],
              const SizedBox(height: Space.lg),
              FilledButton(
                onPressed: state.saving
                    ? null
                    : () => _save(
                        context,
                        ref,
                        _fields.applyTo(_draft),
                        popOnSuccess: true,
                      ),
                child: state.saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recolhe o texto digitado, salva, e conta o que aconteceu.
///
/// Mudar o perfil muda o insumo do treino e da dieta, e o aviso diz isso — senão a pessoa
/// troca o objetivo, vê o plano antigo continuar igual e conclui que o app ignorou.
Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  OnboardingForm form, {
  required bool popOnSuccess,
}) async {
  final controller = ref.read(onboardingControllerProvider.notifier);
  final hadProfile = ref.read(onboardingControllerProvider).hasProfile;

  controller.update(form);

  if (!await controller.submit() || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  if (popOnSuccess && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          hadProfile
              ? 'Perfil salvo. Gere o treino ou a dieta de novo para usar os dados novos.'
              : 'Perfil criado.',
        ),
      ),
    );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: Radii.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
