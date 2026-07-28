import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/reset_password_page.dart';
import '../features/billing/billing_page.dart';
import '../features/coach/coach_page.dart';
import '../features/diary/diary_page.dart';
import '../features/diet/diet_plan_page.dart';
import '../features/home/home_page.dart';
import '../features/logging/log_session_page.dart';
import '../features/meals/meal_analysis_page.dart';
import '../features/privacy/account_page.dart';
import '../features/profile/onboarding_page.dart';
import '../features/reviews/review_page.dart';
import '../features/splash/splash_page.dart';
import '../features/videos/video_analysis_page.dart';
import '../features/workout/workout_plan_page.dart';
import 'deep_links.dart';
import 'providers.dart';

/// Rotas do app. Os caminhos espelham os da SPA (`frontend/src/App.tsx`) para que os
/// deep links de e-mail — como `/redefinir-senha?uid=...&token=...` — funcionem sem que o
/// backend precise saber se quem abriu foi o navegador ou o app.
class Routes {
  const Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/esqueci-a-senha';
  static const resetPassword = '/redefinir-senha';

  static const home = '/';
  static const profile = '/perfil';
  static const workoutPlan = '/treino';
  static const workoutMode = '/treinar';
  static const dietPlan = '/dieta';
  static const logSession = '/registrar';
  static const mealAnalysis = '/refeicoes';
  static const diary = '/diario';
  static const videoAnalysis = '/videos';
  static const review = '/revisao';

  /// Chat com o coach. Não existe na SPA — lá o coach é um componente do dashboard; aqui
  /// vira tela própria porque conversa em celular precisa da altura inteira.
  static const coach = '/coach';

  static const billing = '/assinatura';

  /// Conta e privacidade (LGPD). Não existe na SPA — lá a exclusão vive dentro do perfil.
  /// No app ela é tela própria porque as lojas exigem que o caminho para apagar a conta
  /// seja fácil de achar, e um submenu é motivo de recusa na revisão.
  static const account = '/conta';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Destino guardado enquanto a sessão é lida do armazenamento seguro.
  //
  // Numa partida a frio o link chega antes de a sessão resolver, e a guarda abaixo manda
  // tudo para o splash. Sem guardar o destino ele se perde: o redirect só roda de novo
  // quando a sessão fica pronta, e aí a rota corrente já é o splash. É por isso que o link
  // do e-mail abria o app na home em vez da tela de redefinir senha.
  String? pendingLink;

  return GoRouter(
    // A rota inicial é traduzida aqui, e não deixada a cargo do go_router, porque ele
    // destrói justamente o formato mais comum. Em `_effectiveInitialLocation` ele lê
    // `defaultRouteName` como se fosse só um caminho: `myotrack://diario` tem path vazio,
    // então ele reescreve como `Uri(path: '/')` e o "diario" — que mora no host — some. O
    // app abria na home, e o redirect abaixo nunca chegava a ver o link. Medido no
    // emulador: a rota que chegava era `/?`, exatamente o que aquela reescrita produz.
    //
    // `overridePlatformDefaultLocation` é o que permite ignorar essa conta e usar a nossa.
    // Só vale para a partida a frio; link com o app aberto entra por `pushRouteInformation`
    // e cai direto no redirect.
    overridePlatformDefaultLocation: true,
    initialLocation:
        deepLinkPath(
          Uri.parse(
            WidgetsBinding.instance.platformDispatcher.defaultRouteName,
          ),
        ) ??
        Routes.home,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      // O destino do link do e-mail. `uid` e `token` vêm na query montada pelo backend, e
      // são a credencial inteira desta tela — por isso ela lê da URI em vez de `extra`:
      // `extra` não sobrevive a um link vindo de fora do app.
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) => ResetPasswordPage(
          userId: state.uri.queryParameters['uid'],
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: Routes.workoutPlan,
        builder: (_, _) => const WorkoutPlanPage(),
      ),
      GoRoute(path: Routes.dietPlan, builder: (_, _) => const DietPlanPage()),
      GoRoute(path: Routes.diary, builder: (_, _) => const DiaryPage()),
      GoRoute(
        path: Routes.mealAnalysis,
        builder: (_, _) => const MealAnalysisPage(),
      ),
      GoRoute(
        path: Routes.videoAnalysis,
        builder: (_, _) => const VideoAnalysisPage(),
      ),
      GoRoute(
        path: Routes.logSession,
        builder: (_, _) => const LogSessionPage(),
      ),
      GoRoute(path: Routes.coach, builder: (_, _) => const CoachPage()),
      GoRoute(path: Routes.review, builder: (_, _) => const ReviewPage()),
      GoRoute(path: Routes.billing, builder: (_, _) => const BillingPage()),
      GoRoute(path: Routes.account, builder: (_, _) => const AccountPage()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
    ],
    redirect: (context, state) {
      // Link vindo de fora (e-mail, navegador, outro app) chega com esquema, às vezes com
      // host, e às vezes com barra final. Canonizar antes de qualquer guarda é o que faz o
      // mesmo endereço abrir a tela certa venha ele como https://myotrack.app/... ou
      // myotrack://... — e é o que impede a barra final de virar "rota não encontrada".
      final canonical = deepLinkPath(state.uri);
      if (canonical == null) {
        return Routes.home;
      }
      if (canonical != state.uri.toString()) {
        return canonical;
      }

      final auth = ref.read(authStateProvider);

      // Enquanto a leitura do armazenamento seguro não termina, fica no splash:
      // decidir cedo demais mandaria ao login um usuário que tem sessão válida. O destino
      // é guardado para não se perder nessa espera.
      if (auth.isLoading) {
        if (state.matchedLocation == Routes.splash) {
          return null;
        }
        pendingLink = canonical;
        return Routes.splash;
      }

      // Sessão resolvida: retoma o que o link pedia antes da espera.
      if (pendingLink != null && state.matchedLocation == Routes.splash) {
        final target = pendingLink;
        pendingLink = null;
        return target;
      }

      final loggedIn = auth.valueOrNull ?? false;
      final atPublicRoute = _publicRoutes.contains(state.matchedLocation);

      if (!loggedIn) {
        return atPublicRoute ? null : Routes.login;
      }
      // Já autenticado não volta para login nem fica preso no splash. A redefinição é a
      // exceção: quem pediu o link continua logado no celular na maioria das vezes — é
      // justamente por ainda ter sessão que a pessoa não notou que esqueceu a senha. Mandá-la
      // para a home aqui faria o link do e-mail não funcionar no caso mais comum.
      if (state.matchedLocation == Routes.resetPassword) {
        return null;
      }
      if (atPublicRoute || state.matchedLocation == Routes.splash) {
        return Routes.home;
      }
      return null;
    },
    // Reavalia o redirect quando a sessão muda (login, logout, refresh expirado).
    refreshListenable: _AuthChangeNotifier(ref),
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Rota não encontrada: ${state.uri}')),
    ),
  );
});

const _publicRoutes = {
  Routes.login,
  Routes.forgotPassword,
  Routes.resetPassword,
};

/// Ponte entre o Riverpod e o go_router: converte a mudança do [authStateProvider]
/// em uma notificação que dispara o `redirect`.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}
