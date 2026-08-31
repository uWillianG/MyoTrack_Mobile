import 'package:flutter/material.dart';

import '../../core/router.dart';

/// Em que parte da aba Conta um destino aparece.
///
/// Os grupos existem para a aba, não para a folha: cinco linhas seguidas sem cabeçalho são uma
/// lista para ler inteira, e o que se procura numa tela de conta ("onde mudo o plano?") se acha
/// pelo título do grupo antes de pelo título da linha. A folha continua mostrando tudo em fila
/// — nela são cinco itens numa gaveta que já se abriu com um objetivo em mente.
enum AccountGroup {
  /// Quem é você aqui, quanto você paga, e como sair ou apagar tudo.
  conta('Conta', Icons.badge_outlined),

  /// O que o app gerou para você. Não é conta, mas também não cabe nas outras abas: o plano
  /// inteiro e a conversa com o coach são consulta, e é aqui que se procura por elas quando não
  /// se está no cartão do dia.
  planos('Seus planos', Icons.assignment_outlined),

  /// Só para quem revisa. Grupo próprio e não um item solto no fim da lista: é trabalho de
  /// outra pessoa que não a dona da conta, e misturá-lo com "excluir minha conta" faria as duas
  /// coisas parecerem da mesma natureza.
  revisao('Revisão', Icons.fact_check_outlined);

  const AccountGroup(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Um destino do app que não é uma das cinco abas.
class AccountDestination {
  const AccountDestination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.group,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final AccountGroup group;
}

/// Os destinos que não cabem na barra inferior.
///
/// **Mora em arquivo próprio porque é o mapa do app, e não o desenho de uma folha.** A tela de
/// perfil já repetiu esta mesma lista, e a repetição custava caro dos dois lados: quem abria o
/// perfil para mudar o objetivo encontrava um índice do app inteiro embaixo das próprias
/// medidas, e a lista escrita à mão em dois lugares divergiria na primeira tela nova.
///
/// **Hoje quem a mostra são dois lugares, e é por isso que ela importa mais do que antes**: a
/// aba Conta, agrupada por [AccountGroup], e a folha do avatar, em fila. Nenhum dos dois escreve
/// destino nenhum à mão — é o que garante que a aba e a folha nunca ofereçam coisas diferentes.
///
/// A exclusão de conta, em particular, precisa ser fácil de achar ou a revisão das lojas
/// recusa o app.
const List<AccountDestination> accountDestinations = [
  // **Primeiro da lista, e primeiro do primeiro grupo.** O Perfil é onde moram objetivo e
  // medidas — o que alimenta tudo que o app gera —, e é o que alguém abre quando a resposta do
  // app deixou de servir. Assinatura e privacidade vêm logo atrás porque são a mesma conversa:
  // esta conta, este plano, estes dados.
  AccountDestination(
    icon: Icons.person_outline,
    title: 'Meu perfil',
    subtitle: 'Objetivo, medidas e o que alimenta seus planos',
    route: Routes.profile,
    group: AccountGroup.conta,
  ),
  AccountDestination(
    icon: Icons.workspace_premium_outlined,
    title: 'Assinatura',
    subtitle: 'Seu plano e os limites diários de análise',
    route: Routes.billing,
    group: AccountGroup.conta,
  ),
  AccountDestination(
    icon: Icons.shield_outlined,
    title: 'Conta e privacidade',
    // A exclusão continua nomeada na legenda: é por esta palavra que a pessoa — e o revisor
    // da loja — procura. As outras duas entraram quando a tela deixou de ser só o botão de
    // apagar, senão "sair da conta" viraria uma função que só encontra quem já sabe onde é.
    subtitle: 'Sair, baixar seus dados ou excluir sua conta',
    route: Routes.account,
    group: AccountGroup.conta,
  ),
  AccountDestination(
    icon: Icons.fitness_center_outlined,
    title: 'Meu treino',
    subtitle: 'O plano inteiro, dia a dia',
    route: Routes.workoutPlan,
    group: AccountGroup.planos,
  ),
  AccountDestination(
    icon: Icons.chat_bubble_outline,
    title: 'Coach',
    subtitle: 'Tire dúvidas com quem conhece seu treino e sua dieta',
    route: Routes.coach,
    group: AccountGroup.planos,
  ),
];

/// A revisão só aparece para quem pode revisar: mostrar para o aluno o levaria a uma tela que
/// o servidor recusa com 403, e item de menu que dá erro é pior que item nenhum.
const AccountDestination reviewDestination = AccountDestination(
  icon: Icons.fact_check_outlined,
  title: 'Revisão',
  subtitle: 'Fila de planos aguardando sua aprovação',
  route: Routes.review,
  group: AccountGroup.revisao,
);
