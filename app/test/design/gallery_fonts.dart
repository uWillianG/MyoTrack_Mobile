import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega Roboto e os ícones do Material na galeria visual.
///
/// Sem isto o `flutter test` desenha tudo com a fonte de teste, que é um retângulo por
/// glifo: dá para conferir layout, mas não é possível julgar peso, entrelinha ou
/// espaçamento — que é justamente o que a galeria existe para mostrar. As fontes vêm do
/// cache do SDK em vez de irem para `assets/`, porque só os testes precisam delas e um
/// binário de fonte no repositório é peso morto no app.
Future<void> loadGalleryFonts() async {
  final root = _materialFontsDir();
  if (root == null) {
    return;
  }

  await _load('Roboto', root, {
    'roboto-regular.ttf': FontWeight.w400,
    'roboto-medium.ttf': FontWeight.w500,
    'roboto-bold.ttf': FontWeight.w700,
    'roboto-light.ttf': FontWeight.w300,
    'roboto-black.ttf': FontWeight.w900,
  });
  await _load('MaterialIcons', root, {
    'materialicons-regular.otf': FontWeight.w400,
  });
}

Future<void> _load(
  String family,
  Directory root,
  Map<String, FontWeight> files,
) async {
  // Um FontLoader por peso: o `load()` de um loader só aceita variações da mesma família, e
  // registrar todos os pesos num loader só faria o Flutter tratar o primeiro como único.
  for (final entry in files.entries) {
    final file = File('${root.path}${Platform.pathSeparator}${entry.key}');
    if (!file.existsSync()) {
      continue;
    }
    final loader = FontLoader(
      family,
    )..addFont(file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
    await loader.load();
  }
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
