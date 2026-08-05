import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/design/typography.dart';

/// Carrega a fonte do app e os ícones do Material na galeria visual.
///
/// Sem isto o `flutter test` desenha tudo com a fonte de teste, que é um retângulo por glifo:
/// dá para conferir layout, mas não é possível julgar peso, entrelinha ou espaçamento — que é
/// justamente o que a galeria existe para mostrar.
///
/// **A Manrope vem de `assets/`, lida do disco.** Ela é a fonte do app agora, então a captura
/// mostra o que o usuário vê. Ler o arquivo direto, em vez de pelo `rootBundle`, evita
/// depender de o manifesto de assets estar montado no ambiente de teste — o caminho relativo
/// funciona porque o `flutter test` roda com o diretório do pacote como raiz.
///
/// Os ícones continuam vindo do cache do SDK: eles não moram no repositório.
Future<void> loadGalleryFonts() async {
  await _loadFile(AppTypography.family, 'assets/fonts/Manrope-Variable.ttf');

  final root = _materialFontsDir();
  if (root == null) {
    return;
  }
  await _loadFile(
    'MaterialIcons',
    '${root.path}${Platform.pathSeparator}materialicons-regular.otf',
  );
}

Future<void> _loadFile(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return;
  }
  final loader = FontLoader(family)
    ..addFont(file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
  await loader.load();
}

/// O diretório `material_fonts` do cache do SDK, achado a partir do executável do Dart.
///
/// `Platform.resolvedExecutable` aponta para `bin/cache/dart-sdk/bin/dart` dentro do próprio
/// Flutter, então subir quatro níveis chega em `bin/cache`. É o caminho que não depende de
/// FLUTTER_ROOT estar no ambiente — no CI ele costuma não estar.
Directory? _materialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6; i++) {
    final candidate = Directory(
      '${dir.path}${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}material_fonts',
    );
    if (candidate.existsSync()) {
      return candidate;
    }
    if (dir.parent.path == dir.path) {
      break;
    }
    dir = dir.parent;
  }
  return null;
}
