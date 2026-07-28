import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';

/// Tela inicial provisória: uma lista das telas já prontas.
///
/// O dashboard de verdade (gráficos, recordes, card do relatório) entra em B10. Até lá isto
/// existe para que cada funcionalidade nova seja alcançável assim que fica pronta — sem
/// ponto de entrada, ela só poderia ser testada por deep link.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyoTrack')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Treinar agora'),
            subtitle: const Text(
              'Conduz o treino série a série, com timer de descanso',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.workoutMode),
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center_outlined),
            title: const Text('Meu treino'),
            subtitle: const Text('Plano gerado a partir do seu perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.workoutPlan),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_outlined),
            title: const Text('Minha dieta'),
            subtitle: const Text('Refeições e metas calculadas pelo seu peso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.dietPlan),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Analisar refeição'),
            subtitle: const Text(
              'Fotografe o prato e a IA estima calorias e macros',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.mealAnalysis),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('Registrar treino'),
            subtitle: const Text(
              'Séries, cargas e peso corporal — funciona offline',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.logSession),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            subtitle: const Text(
              'Objetivo, experiência, equipamentos e lesões',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.profile),
          ),
        ],
      ),
    );
  }
}
