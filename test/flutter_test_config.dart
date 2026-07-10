import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts for golden tests so images reflect actual rendering
/// instead of the default Ahem placeholder glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(_loadRealFonts);
  await testMain();
}

Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;

  final fontsDir = Directory(
    '$flutterRoot/bin/cache/artifacts/material_fonts',
  );
  if (!fontsDir.existsSync()) return;

  for (final entity in fontsDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.ttf')) continue;
    final bytes = await entity.readAsBytes();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(bytes.buffer.asByteData()));
    await loader.load();
  }
}
