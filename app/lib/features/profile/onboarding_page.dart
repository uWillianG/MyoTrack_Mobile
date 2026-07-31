import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/profile_models.dart';
import 'onboarding_controller.dart';
import 'widgets/form_section.dart';

/// Perfil e onboarding, em cinco etapas.
///
/// Uma pergunta de cada vez, e não o formulário inteiro numa rolagem só. O formulário longo
/// funcionava para quem voltava editar um campo, mas era a **primeira** tela de quem instalou
/// o app: catorze campos de uma vez, num assunto em que quase tudo é opcional, é onde a
/// pessoa desiste. Em etapas cada tela pede duas ou três coisas e diz para que servem.
///
/// Rota própria (`/perfil`); o conteúdo mora em [OnboardingView] porque a aba Perfil do hub
/// diário mostra o mesmo assistente sob a barra de título dela.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.hasProfile ? 'Meu perfil' : 'Vamos começar'),
        automaticallyImplyLeading: state.hasProfile,
      ),
      body: const OnboardingView(),
    );
  }
}

/// As cinco etapas, sem a barra de título.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _injuryNotes = TextEditingController();
  final _restrictions = TextEditingController();
  final _preferences = TextEditingController();

  /// Os controllers de texto só podem ser preenchidos depois que o perfil chega do
  /// servidor — e uma vez só, senão sobrescrevem o que o usuário está digitando.
  bool _textFieldsSeeded = false;

  int _step = 0;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _injuryNotes.dispose();
    _restrictions.dispose();
    _preferences.dispose();
    super.dispose();
  }

  void _seedTextFields(OnboardingForm form) {
    if (_textFieldsSeeded) {
      return;
    }
    _textFieldsSeeded = true;
    _height.text = form.heightCm;
    _weight.text = form.weightKg;
    _injuryNotes.text = form.injuryNotes;
    _restrictions.text = form.dietaryRestrictions;
    _preferences.text = form.foodPreferences;
  }

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  Future<void> _pickBirthDate(OnboardingForm form) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: form.birthDate ?? DateTime(now.year - 30),
      // Faixa que cobre qualquer usuário plausível sem permitir data absurda.
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 12),
      helpText: 'Data de nascimento',
    );
    if (picked != null) {
      _controller.update(form.copyWith(birthDate: picked));
    }
  }

  /// Passa o que está digitado nos campos livres para o formulário.
  ///
  /// Chamado ao trocar de etapa, e não a cada tecla: reconstruir a tela a cada letra é o que
  /// fazia o teclado engasgar nos campos de restrições.
  OnboardingForm _withTypedText() {
    final form = ref
        .read(onboardingControllerProvider)
        .form
        .copyWith(
          heightCm: _height.text,
          weightKg: _weight.text,
          injuryNotes: _injuryNotes.text,
          dietaryRestrictions: _restrictions.text,
          foodPreferences: _preferences.text,
        );
    _controller.update(form);
    return form;
  }

  void _back() {
    _withTypedText();
    setState(() => _step = _step - 1);
  }

  Future<void> _next() async {
    _withTypedText();

    if (_step < _lastStep) {
      // Fecha o teclado antes de trocar de etapa: aberto, ele cobre as opções da etapa
      // seguinte e a pessoa não vê que a tela mudou.
      FocusScope.of(context).unfocus();
      setState(() => _step = _step + 1);
      return;
    }

    if (await _controller.submit() && mounted) {
      final message = ref.read(onboardingControllerProvider).hasProfile
          ? 'Perfil salvo. Seu plano será regerado com estes dados.'
          : 'Perfil salvo.';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));

      // Numa tela empilhada (`/perfil`) volta para quem chamou; na aba Perfil não há o que
      // desempilhar, e o assistente fica de pé para uma nova edição.
      if (context.canPop()) {
        context.pop();
      } else {
        setState(() => _step = 0);
      }
    }
  }

  static const int _lastStep = 4;

  static const _titles = [
    'Quem está treinando',
    'Como você treina',
    'O que você tem à mão',
    'O que evitar',
    'O que você come',
  ];

  static const _labels = [
    'Você',
    'Seu treino',
    'Equipamento',
    'Lesões',
    'Alimentação',
  ];

  static const _helps = [
    'Usados para calcular seu gasto calórico.',
    'O número de dias define o split do seu plano.',
    'Deixe tudo desmarcado se treina em academia completa.',
    'Exercícios com risco para as áreas marcadas ficam fora do treino.',
    'Separe por vírgula. Tudo é opcional.',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final form = state.form;
    final theme = Theme.of(context);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    _seedTextFields(form);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_step + 1) / (_lastStep + 1),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Etapa ${_step + 1}/${_lastStep + 1} · ${_labels[_step]}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(_titles[_step], style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                _helps[_step],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              if (state.error != null) ...[
                _ErrorBanner(message: state.error!),
                const SizedBox(height: 16),
              ],

              ..._stepBody(form, state),
            ],
          ),
        ),
        // Preso no rodapé, e não no fim da rolagem: a etapa "Quem está treinando" já passa
        // da altura de um celular pequeno, e um "Continuar" que só aparece depois de rolar
        // faz o assistente parecer sem saída.
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: state.saving ? null : _back,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(104, 48),
                  ),
                  child: const Text('Voltar'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: state.saving ? null : _next,
                  child: state.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step < _lastStep ? 'Continuar' : 'Salvar perfil'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _stepBody(OnboardingForm form, OnboardingState state) =>
      switch (_step) {
        0 => _you(form),
        1 => _training(form),
        2 => _equipment(form),
        3 => _injuries(form),
        _ => _food(form, state),
      };

  // ---------------- Etapa 1: você ----------------
  List<Widget> _you(OnboardingForm form) => [
    _Group(
      label: 'Sexo',
      child: SingleChoiceChips(
        options: ProfileOptions.sexes,
        value: form.sex,
        onSelected: (v) => _controller.update(form.copyWith(sex: v)),
      ),
    ),
    _Group(
      label: 'Biotipo',
      child: SingleChoiceChips(
        options: ProfileOptions.biotypes,
        value: form.biotype,
        // Tocar no chip já marcado desmarca — o campo é opcional.
        onSelected: (v) => _controller.update(
          form.copyWith(biotype: form.biotype == v ? '' : v),
        ),
      ),
    ),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Altura (cm)',
              hintText: '175',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              hintText: '80',
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    // Data de nascimento não está no protótipo, mas entra aqui porque é metade do cálculo
    // do gasto calórico — sem ela a dieta sai de uma estimativa pior.
    InkWell(
      onTap: () => _pickBirthDate(form),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data de nascimento',
          prefixIcon: Icon(Icons.cake_outlined),
        ),
        child: Text(
          form.birthDate == null
              ? 'Não informado'
              : _formatDate(form.birthDate!),
        ),
      ),
    ),
  ];

  // ---------------- Etapa 2: treino ----------------
  List<Widget> _training(OnboardingForm form) => [
    _Group(
      label: 'Experiência',
      child: SingleChoiceChips(
        options: ProfileOptions.experienceLevels,
        value: form.experienceLevel,
        onSelected: (v) =>
            _controller.update(form.copyWith(experienceLevel: v)),
      ),
    ),
    _Group(
      label: 'Objetivo',
      child: SingleChoiceChips(
        options: ProfileOptions.goals,
        value: form.goal,
        onSelected: (v) => _controller.update(form.copyWith(goal: v)),
      ),
    ),
    _Group(
      label: 'Dias de treino por semana: ${form.trainingDaysPerWeek}',
      // Sete botões em vez de um `Slider`: o valor é o assunto da pergunta, e num slider ele
      // só aparece na bolha enquanto o dedo está em cima. Aqui os sete estão à vista, e o
      // alvo de toque é maior que a trilha de 4 dp.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var day = 1; day <= 7; day++) ...[
                if (day > 1) const SizedBox(width: 8),
                Expanded(
                  child: _DayTick(
                    day: day,
                    selected: form.trainingDaysPerWeek == day,
                    onTap: () => _controller.update(
                      form.copyWith(trainingDaysPerWeek: day),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            splitHint(form.trainingDaysPerWeek),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
    _Group(
      label: 'Grupos que quer priorizar',
      child: OptionChips(
        options: ProfileOptions.muscleGroups,
        selected: form.priorityMuscleGroups,
        onToggle: (v) => _controller.update(
          form.copyWith(
            priorityMuscleGroups: OnboardingController.toggle(
              form.priorityMuscleGroups,
              v,
            ),
          ),
        ),
      ),
    ),
  ];

  // ---------------- Etapa 3: equipamento ----------------
  List<Widget> _equipment(OnboardingForm form) => [
    _Group(
      label: 'Equipamento disponível',
      child: OptionChips(
        options: ProfileOptions.equipment,
        selected: form.availableEquipment,
        onToggle: (v) => _controller.update(
          form.copyWith(
            availableEquipment: OnboardingController.toggle(
              form.availableEquipment,
              v,
            ),
          ),
        ),
      ),
    ),
  ];

  // ---------------- Etapa 4: lesões ----------------
  List<Widget> _injuries(OnboardingForm form) => [
    _Group(
      label: 'Áreas sensíveis',
      child: OptionChips(
        options: ProfileOptions.injuries,
        selected: form.injuryTags,
        onToggle: (v) => _controller.update(
          form.copyWith(
            injuryTags: OnboardingController.toggle(form.injuryTags, v),
          ),
        ),
      ),
    ),
    TextField(
      controller: _injuryNotes,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Observações (opcional)',
        hintText: 'Ex.: dor no ombro direito ao elevar acima da cabeça',
      ),
    ),
  ];

  // ---------------- Etapa 5: alimentação ----------------
  List<Widget> _food(OnboardingForm form, OnboardingState state) => [
    TextField(
      controller: _restrictions,
      decoration: const InputDecoration(
        labelText: 'Restrições',
        hintText: 'lactose, glúten, camarão',
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _preferences,
      decoration: const InputDecoration(
        labelText: 'Preferências',
        hintText: 'frango, arroz, banana',
      ),
    ),
    // O consentimento não está no protótipo e não é negociável: sem ele o app trata dado de
    // saúde sem base legal. Fica na última etapa, que é onde o botão salva de verdade.
    if (!state.hasProfile) ...[
      const SizedBox(height: 16),
      Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CheckboxListTile(
            value: form.consented,
            onChanged: (v) =>
                _controller.update(form.copyWith(consented: v ?? false)),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Autorizo o tratamento dos meus dados de saúde'),
            subtitle: const Text(
              'Peso, medidas, lesões e histórico de treino são usados para gerar '
              'seu plano. Você pode exportar ou apagar tudo quando quiser.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    ],
  ];

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

/// Que divisão sai de cada quantidade de dias.
///
/// A frase existe para a escolha não ser às cegas: "4" não diz nada, "4 dias — ABCD" diz. É a
/// mesma regra que o gerador aplica no servidor, escrita aqui só para antecipar o resultado.
String splitHint(int days) => switch (days) {
  1 => '1 dia — corpo inteiro',
  2 => '2 dias — corpo inteiro',
  3 => '3 dias — ABC',
  4 => '4 dias — ABCD',
  5 => '5 dias — push/pull/legs',
  6 => '6 dias — push/pull/legs 2×',
  _ => '7 dias — considere deixar um dia de descanso',
};

class _DayTick extends StatelessWidget {
  const _DayTick({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      label: '$day ${day == 1 ? 'dia' : 'dias'} por semana',
      child: Material(
        color: selected ? theme.colorScheme.primary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? Colors.transparent : theme.colorScheme.outline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                '$day',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rótulo e conteúdo de um grupo de opções dentro da etapa.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
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
