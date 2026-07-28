import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/sync/background_sync.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registra o callback de background e a agenda recorrente da fila de escrita (B6). Falhar
  // aqui não pode impedir o app de abrir: sem o agendador a fila continua subindo na próxima
  // escrita, que é como o app funcionava antes.
  try {
    await WorkManagerSync.initialize();
  } catch (error, stack) {
    debugPrint('Sincronização em background indisponível: $error\n$stack');
  }

  runApp(const ProviderScope(child: MyoTrackApp()));
}

class MyoTrackApp extends ConsumerWidget {
  const MyoTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MyoTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      // O app é só em pt-BR: os textos vêm prontos do backend nesse idioma
      // (mensagens de erro, nomes de exercícios e alimentos).
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
