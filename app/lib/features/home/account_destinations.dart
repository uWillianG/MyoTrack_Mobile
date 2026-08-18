import 'package:flutter/material.dart';

import '../../core/router.dart';

/// Um destino do app que não é uma das quatro abas.
class AccountDestination {
  const AccountDestination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

/// Os destinos que não cabem na barra inferior.
///
/// **Mora em arquivo próprio porque aparece em dois lugares.** A folha do avatar é o atalho de
/// quem está no meio de outra coisa; a tela de perfil repete a mesma lista para quem chegou lá
/// *procurando* — e é ali que quase todo app põe conta, assinatura e configuração. Duas listas
/// escritas à mão divergem na primeira tela nova, e aí o mesmo app passa a ter dois mapas
/// diferentes de si mesmo.
///
/// **O Progresso saiu daqui ao virar aba.** Repetido nos dois lugares ele sugeriria que a folha
/// leva a uma tela diferente da barra. Quem ocupou a vaga foi o próprio Perfil, que fez o
/// caminho contrário — ver [HomeTab].
///
/// A exclusão de conta, em particular, precisa ser fácil de achar ou a revisão das lojas
/// recusa o app.
const List<AccountDestination> accountDestinations = [
  // **Primeiro da lista desde que o Progresso tomou o lugar dele na barra.** O Perfil é onde
  // moram objetivo, medidas e o caminho para assinatura e exclusão de conta: coisas que se
  // mexe uma vez. Atrás do avatar é onde qualquer app as põe, e é onde a pessoa procura.
  AccountDestination(
    icon: Icons.person_outline,
    title: 'Meu perfil',
    subtitle: 'Objetivo, medidas e o que alimenta seus planos',
    route: Routes.profile,
  ),
  AccountDestination(
    icon: Icons.fitness_center_outlined,
    title: 'Meu treino',
    subtitle: 'O plano inteiro, dia a dia',
    route: Routes.workoutPlan,
  ),
  AccountDestination(
    icon: Icons.edit_note_outlined,
    title: 'Registrar treino',
    subtitle: 'Séries, cargas e peso corporal — funciona offline',
    route: Routes.logSession,
  ),
  AccountDestination(
    icon: Icons.chat_bubble_outline,
    title: 'Coach',
    subtitle: 'Tire dúvidas com quem conhece seu treino e sua dieta',
    route: Routes.coach,
  ),
  AccountDestination(
    icon: Icons.workspace_premium_outlined,
    title: 'Assinatura',
    subtitle: 'Seu plano e os limites diários de análise',
    route: Routes.billing,
  ),
  AccountDestination(
    icon: Icons.shield_outlined,
    title: 'Conta e privacidade',
    subtitle: 'Excluir sua conta e todos os seus dados',
    route: Routes.account,
  ),
];

/// A revisão só aparece para quem pode revisar: mostrar para o aluno o levaria a uma tela que
/// o servidor recusa com 403, e item de menu que dá erro é pior que item nenhum.
const AccountDestination reviewDestination = AccountDestination(
  icon: Icons.fact_check_outlined,
  title: 'Revisão',
  subtitle: 'Fila de planos aguardando sua aprovação',
  route: Routes.review,
);
