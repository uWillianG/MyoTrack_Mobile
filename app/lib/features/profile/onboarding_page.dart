import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import 'data/profile_models.dart';
import 'onboarding_controller.dart';
import 'widgets/form_section.dart';

/// Perfil e onboarding. Porte de `OnboardingPage.tsx`.
///
/// Serve aos dois casos: primeiro preenchimento (exige consentimento LGPD) e edição
/// posterior (o consentimento já está registrado).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _injuryNotes = TextEditingController();
  final _restrictions = TextEditingController();
  final _preferences = TextEditingController();

  /// Os controllers de texto só podem ser preenchidos depois que o perfil chega do
  /// servidor — e uma vez só, senão sobrescrevem o que o usuário está digitando.
  bool _textFieldsSeeded = false;

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

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  Future<void> _submit() async {
    // O texto dos campos livres só é lido no envio — evita reconstruir a tela a cada tecla.
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

    if (await _controller.submit() && mounted) {
      // Depois do onboarding o destino natural é o treino — que ainda não existe,
      // então por ora volta para a home.
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final form = state.form;
    final theme = Theme.of(context);

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _seedTextFields(form);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.hasProfile ? 'Meu perfil' : 'Vamos começar'),
        automaticallyImplyLeading: state.hasProfile,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (!state.hasProfile)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Estas informações moldam seu treino e sua dieta. '
                  'Quase tudo é opcional — dá para ajustar depois.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            if (state.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                        state.error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ---------------- Você ----------------
            FormSection(
              title: 'Você',
              description: 'Usados para calcular seu gasto calórico.',
              children: [
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
                const SizedBox(height: 12),
                SingleChoiceChips(
                  options: ProfileOptions.sexes,
                  value: form.sex,
                  onSelected: (v) => _controller.update(form.copyWith(sex: v)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _height,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                Text('Biotipo', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SingleChoiceChips(
                  options: ProfileOptions.biotypes,
                  value: form.biotype,
                  onSelected: (v) => _controller.update(
                    // Tocar no chip já marcado desmarca — o campo é opcional.
                    form.copyWith(biotype: form.biotype == v ? '' : v),
                  ),
                ),
              ],
            ),

            // ---------------- Treino ----------------
            FormSection(
              title: 'Seu treino',
              children: [
                Text('Experiência', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SingleChoiceChips(
                  options: ProfileOptions.experienceLevels,
                  value: form.experienceLevel,
                  onSelected: (v) =>
                      _controller.update(form.copyWith(experienceLevel: v)),
                ),
                const SizedBox(height: 16),
                Text('Objetivo', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SingleChoiceChips(
                  options: ProfileOptions.goals,
                  value: form.goal,
                  onSelected: (v) => _controller.update(form.copyWith(goal: v)),
                ),
                const SizedBox(height: 16),
                // O número de dias define o split: 2 = full body, 3 = ABC, 4 = ABCD, 5+ = PPL.
                Text(
                  'Dias de treino por semana: ${form.trainingDaysPerWeek}',
                  style: theme.textTheme.labelLarge,
                ),
                Slider(
                  value: form.trainingDaysPerWeek.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '${form.trainingDaysPerWeek}',
                  onChanged: (v) => _controller.update(
                    form.copyWith(trainingDaysPerWeek: v.round()),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grupos que quer priorizar',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                OptionChips(
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
              ],
            ),

            // ---------------- Equipamento ----------------
            FormSection(
              title: 'Equipamento disponível',
              description:
                  'Deixe tudo desmarcado se treina em academia completa.',
              children: [
                OptionChips(
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
              ],
            ),

            // ---------------- Lesões ----------------
            FormSection(
              title: 'Lesões e limitações',
              description:
                  'Exercícios com risco para as áreas marcadas ficam fora do seu treino.',
              children: [
                OptionChips(
                  options: ProfileOptions.injuries,
                  selected: form.injuryTags,
                  onToggle: (v) => _controller.update(
                    form.copyWith(
                      injuryTags: OnboardingController.toggle(
                        form.injuryTags,
                        v,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _injuryNotes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText:
                        'Ex.: dor no ombro direito ao elevar acima da cabeça',
                  ),
                ),
              ],
            ),

            // ---------------- Alimentação ----------------
            FormSection(
              title: 'Alimentação',
              description: 'Separe por vírgula.',
              children: [
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
              ],
            ),

            // ---------------- Consentimento ----------------
            if (!state.hasProfile)
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CheckboxListTile(
                    value: form.consented,
                    onChanged: (v) => _controller.update(
                      form.copyWith(consented: v ?? false),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Autorizo o tratamento dos meus dados de saúde',
                    ),
                    subtitle: const Text(
                      'Peso, medidas, lesões e histórico de treino são usados para gerar '
                      'seu plano. Você pode exportar ou apagar tudo quando quiser.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),

            FilledButton(
              onPressed: state.saving ? null : _submit,
              child: state.saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(state.hasProfile ? 'Salvar' : 'Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
