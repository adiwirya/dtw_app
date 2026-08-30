import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts for golden tests so images reflect actual rendering
/// instead of the default Ahem placeholder glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Every loader below reads through `rootBundle`, which needs a binding.
  // A file containing only plain `test()` cases never initializes one on its
  // own — `testWidgets` is what used to do it by side effect — so those files
  // died in `setUpAll` with "Binding has not yet been initialized" before
  // their first test ran. `ensureInitialized` is idempotent.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);
  setUpAll(_loadAppFonts);
  setUpAll(_loadRealFonts);
  setUpAll(_loadObraIcons);
  await testMain();
}

/// Loads the app's own bundled families (`assets/fonts/`) so golden tests
/// render real Open Sans / Pacifico rather than the harness fallback. The
/// family names must match `pubspec.yaml` exactly, or `TextStyle`s asking for
/// them silently fall back.
Future<void> _loadAppFonts() async {
  const families = {
    'Open Sans': 'assets/fonts/OpenSans-Variable.ttf',
    'Pacifico': 'assets/fonts/Pacifico-Regular.ttf',
  };
  for (final entry in families.entries) {
    final data = await rootBundle.load(entry.value);
    final loader = FontLoader(entry.key)..addFont(Future.value(data));
    await loader.load();
  }
}

/// Loads the bundled `obra_icons` glyph font so golden tests render its icons
/// (used on the Akun screen) instead of blank notdef boxes.
Future<void> _loadObraIcons() async {
  try {
    final data = await rootBundle.load(
      'packages/obra_icons/fonts/ObraIcons.ttf',
    );
    final loader = FontLoader('ObraIcons')..addFont(Future.value(data));
    await loader.load();
  } on Object catch (_) {
    // Font asset not bundled in this test run; icons fall back to notdef.
    // `on Object`, not `on Exception`: a missing binding throws an *Error*,
    // which an `on Exception` clause lets through to kill the whole file.
  }
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
