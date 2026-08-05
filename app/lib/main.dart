import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/router.dart';
import 'core/sync/background_sync.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _registerFontLicense();

  // Sem isto, o `intl` formata datas em en_US mesmo com o app inteiro em português: o diário
  // mostrava "Wednesday, 28 de July" e as barras da semana vinham com "Mon", "Tue". Os
  // símbolos de data precisam ser carregados, e o locale padrão precisa ser dito — as duas
  // coisas, porque uma sem a outra não resolve.
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

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

/// Põe a licença da Manrope na tela de licenças que o Flutter já monta.
///
/// A OFL exige que o aviso de copyright acompanhe a fonte redistribuída, e um app publicado
/// nas lojas redistribui. O `LicenseRegistry` é onde o `showLicensePage` do Flutter procura —
/// é a diferença entre cumprir a licença e ter um arquivo de texto solto no APK.
///
/// Síncrono de propósito: o registro recebe um `Stream` preguiçoso, então a leitura do arquivo
/// só acontece se alguém abrir a tela de licenças.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope'], license);
  });
}

class MyoTrackApp extends ConsumerWidget {
  const MyoTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MyoTrack',
      debugShowCheckedModeBanner: false,
      // **O app é escuro, sempre.** O fundo preto não é uma variante que o sistema
      // operacional escolhe: é a identidade do produto, e é o que faz os blocos coloridos do
      // mosaico ficarem suspensos no escuro em vez de pintados sobre cinza.
      //
      // `theme` continua apontando para o claro porque o `MaterialApp` o exige, e porque
      // desfazer esta decisão é trocar uma linha — o tema claro segue definido, testado e
      // capturado na galeria.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
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
