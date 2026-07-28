import 'package:flutter/material.dart';

/// Mostrada enquanto a sessão é lida do armazenamento seguro.
///
/// Sem ela haveria um piscar da tela de login antes do app perceber que o usuário
/// já estava autenticado — a leitura do Keychain/KeyStore é assíncrona.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MyoTrack',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
