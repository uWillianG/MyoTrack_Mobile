import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/tokens.dart';
import '../data/profile_models.dart';
import '../onboarding_controller.dart';
import 'form_section.dart';

/// Os cinco grupos de campos do perfil, cada um usável em dois lugares.
///
/// **É o que faz o app ter uma forma só para aprender.** O cadastro empilha os cinco grupos
/// numa rolagem; a edição abre um grupo sozinho numa folha. Os campos são literalmente os
/// mesmos widgets — quem preencheu "Dias de treino" no cadastro reencontra o mesmo controle,
/// no mesmo lugar dentro do grupo, quando volta para mudá-lo meses depois.
///
/// Antes eram cinco etapas de um assistente, e a edição de um único campo custava cinco
/// toques: entrar, avançar até a etapa certa, mudar, e avançar até o fim para achar o botão
/// que salva.

/// Os controllers dos campos livres, num pacote só.
///
/// Existem fora dos editores porque texto não pode reconstruir o formulário a cada tecla — foi
/// o que fazia o teclado engasgar nos campos de restrição. O dono da tela cria, semeia uma vez
/// e recolhe o que foi digitado quando vai salvar.
class ProfileFieldControllers {
  final height = TextEditingController();
  final weight = TextEditingController();
  final injuryNotes = TextEditingController();
  final restrictions = TextEditingController();
  final preferences = TextEditingController();

  /// [lastWeightKg] é a última pesagem conhecida.
  ///
  /// O peso não vem no perfil — ele mora no histórico de medidas —, e por isso o campo abria
  /// **sempre vazio** para quem já usava o app há meses. Um campo em branco onde havia um
  /// número lê como dado perdido, e o usuário redigita o que o app já sabia.
  void seed(OnboardingForm form, {double? lastWeightKg}) {
    height.text = form.heightCm;
    weight.text = form.weightKg.isNotEmpty
        ? form.weightKg
        : (lastWeightKg == null
              ? ''
              : lastWeightKg
                    .toStringAsFixed(
                      lastWeightKg == lastWeightKg.roundToDouble() ? 0 : 1,
                    )
                    .replaceAll('.', ','));
    injuryNotes.text = form.injuryNotes;
    restrictions.text = form.dietaryRestrictions;
    preferences.text = form.foodPreferences;
  }

  /// O formulário com o que está digitado agora.
  OnboardingForm applyTo(OnboardingForm form) => form.copyWith(
    heightCm: height.text,
    weightKg: weight.text,
    injuryNotes: injuryNotes.text,
    dietaryRestrictions: restrictions.text,
    foodPreferences: preferences.text,
  );

  void dispose() {
    height.dispose();
    weight.dispose();
    injuryNotes.dispose();
    restrictions.dispose();
    preferences.dispose();
  }
}

/// Assinatura comum dos cinco editores.
typedef FormChanged = void Function(OnboardingForm form);

// ---------------------------------------------------------------------------------------

/// Sexo, biotipo, altura, peso e nascimento.
class YouEditor extends StatelessWidget {
  const YouEditor({
    super.key,
    required this.form,
    required this.fields,
    required this.onChanged,
  });

  final OnboardingForm form;
  final ProfileFieldControllers fields;
  final FormChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label('Sexo'),
        SingleChoiceChips(
          options: ProfileOptions.sexes,
          value: form.sex,
          onSelected: (v) => onChanged(form.copyWith(sex: v)),
        ),
        const SizedBox(height: Space.lg),
        _Label('Biotipo (opcional)'),
        SingleChoiceChips(
          options: ProfileOptions.biotypes,
          value: form.biotype,
          // Tocar no chip já marcado desmarca — o campo é opcional.
          onSelected: (v) =>
              onChanged(form.copyWith(biotype: form.biotype == v ? '' : v)),
        ),
        // A definição só do escolhido. Dentro dos três rótulos ela fazia cada chip ocupar uma
        // linha inteira e ainda assim sair cortado.
        if (ProfileOptions.biotypeHints[form.biotype] case final hint?)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(hint, style: Theme.of(context).textTheme.bodySmall),
          ),
        const SizedBox(height: Space.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: fields.height,
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
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: fields.weight,
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
        // Fora do campo, e não como `helperText`: em meia largura ele saía cortado em "Vira
        // uma pesage…", que é pior que aviso nenhum.
        const SizedBox(height: Space.xs),
        Text(
          'Salvar grava o peso como uma pesagem nova.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.md),
        // Data de nascimento é metade do cálculo do gasto calórico — sem ela a dieta sai de
        // uma estimativa pior.
        InkWell(
          onTap: () => _pickBirthDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data de nascimento',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            child: Text(
              form.birthDate == null
                  ? 'Não informado'
                  : formatBirthDate(form.birthDate!),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickBirthDate(BuildContext context) async {
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
      onChanged(form.copyWith(birthDate: picked));
    }
  }
}

/// Experiência, objetivo, dias por semana e grupos prioritários.
class TrainingEditor extends StatelessWidget {
  const TrainingEditor({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final OnboardingForm form;
  final FormChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label('Experiência'),
        SingleChoiceChips(
          options: ProfileOptions.experienceLevels,
          value: form.experienceLevel,
          onSelected: (v) => onChanged(form.copyWith(experienceLevel: v)),
        ),
        const SizedBox(height: Space.lg),
        _Label('Objetivo'),
        SingleChoiceChips(
          options: ProfileOptions.goals,
          value: form.goal,
          onSelected: (v) => onChanged(form.copyWith(goal: v)),
        ),
        const SizedBox(height: Space.lg),
        _Label('Dias de treino por semana'),
        // Sete botões em vez de um `Slider`: o valor é o assunto da pergunta, e num slider ele
        // só aparece na bolha enquanto o dedo está em cima. Aqui os sete estão à vista, e o
        // alvo de toque é maior que a trilha de 4 dp.
        Row(
          children: [
            for (var day = 1; day <= 7; day++) ...[
              if (day > 1) const SizedBox(width: Space.xs),
              Expanded(
                child: _DayTick(
                  day: day,
                  selected: form.trainingDaysPerWeek == day,
                  onTap: () =>
                      onChanged(form.copyWith(trainingDaysPerWeek: day)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.xs),
        Text(
          splitHint(form.trainingDaysPerWeek),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: Space.lg),
        _Label('Grupos que quer priorizar (opcional)'),
        OptionChips(
          options: ProfileOptions.muscleGroups,
          selected: form.priorityMuscleGroups,
          onToggle: (v) => onChanged(
            form.copyWith(
              priorityMuscleGroups: OnboardingController.toggle(
                form.priorityMuscleGroups,
                v,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// O que a pessoa tem à mão.
class EquipmentEditor extends StatelessWidget {
  const EquipmentEditor({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final OnboardingForm form;
  final FormChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Deixe tudo desmarcado se treina em academia completa.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.sm),
        OptionChips(
          options: ProfileOptions.equipment,
          selected: form.availableEquipment,
          onToggle: (v) => onChanged(
            form.copyWith(
              availableEquipment: OnboardingController.toggle(
                form.availableEquipment,
                v,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Áreas sensíveis e a observação livre.
class InjuriesEditor extends StatelessWidget {
  const InjuriesEditor({
    super.key,
    required this.form,
    required this.fields,
    required this.onChanged,
  });

  final OnboardingForm form;
  final ProfileFieldControllers fields;
  final FormChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Exercícios com risco para as áreas marcadas ficam fora do treino.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.sm),
        OptionChips(
          options: ProfileOptions.injuries,
          selected: form.injuryTags,
          onToggle: (v) => onChanged(
            form.copyWith(
              injuryTags: OnboardingController.toggle(form.injuryTags, v),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: fields.injuryNotes,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Observações (opcional)',
            hintText: 'Ex.: dor no ombro direito ao elevar acima da cabeça',
          ),
        ),
      ],
    );
  }
}

/// Restrições e preferências alimentares.
class FoodEditor extends StatelessWidget {
  const FoodEditor({super.key, required this.fields});

  final ProfileFieldControllers fields;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Separe por vírgula. Tudo é opcional.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: fields.restrictions,
          decoration: const InputDecoration(
            labelText: 'Restrições',
            hintText: 'lactose, glúten, camarão',
          ),
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: fields.preferences,
          decoration: const InputDecoration(
            labelText: 'Preferências',
            hintText: 'frango, arroz, banana',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
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

String formatBirthDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

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
