import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/diet/diet_plan_page.dart';
import '../features/home/home_page.dart';
import '../features/logging/log_session_page.dart';
import '../features/profile/onboarding_page.dart';
import '../features/splash/splash_page.dart';
import '../features/workout/workout_mode_page.dart';
import '../features/workout/workout_plan_page.dart';
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
  static const billing = '/assinatura';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: Routes.workoutPlan,
        builder: (_, _) => const WorkoutPlanPage(),
      ),
      GoRoute(
        path: Routes.workoutMode,
        builder: (_, _) => const WorkoutModePage(),
      ),
      GoRoute(path: Routes.dietPlan, builder: (_, _) => const DietPlanPage()),
      GoRoute(
        path: Routes.logSession,
        builder: (_, _) => const LogSessionPage(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
    ],
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);

      // Enquanto a leitura do armazenamento seguro não termina, fica no splash:
      // decidir cedo demais mandaria ao login um usuário que tem sessão válida.
      if (auth.isLoading) {
        return state.matchedLocation == Routes.splash ? null : Routes.splash;
      }

      final loggedIn = auth.valueOrNull ?? false;
      final atPublicRoute = _publicRoutes.contains(state.matchedLocation);

      if (!loggedIn) {
        return atPublicRoute ? null : Routes.login;
      }
      // Já autenticado não volta para login nem fica preso no splash.
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
