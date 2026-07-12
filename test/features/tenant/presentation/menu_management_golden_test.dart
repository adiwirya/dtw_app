import 'package:dtw_app/features/tenant/presentation/screens/menu_saya_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/kelola_menu_sheet.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for item 06 (tenant Menu management).
///
/// NOTE: like the other tenant self-goldens, the headless harness renders text
/// as Ahem boxes (Open Sans is not bundled), so these pin layout/structure/
/// colours against regressions rather than pixel-diffing the Figma references;
/// fidelity vs. each `.ftk/figma/.../reference.png` was confirmed separately
/// during the build (see the work-item report). The menu **form** goldens
/// intentionally reflect the L6 requirements (PIN/Populer, discount card, no
/// promo, no stock), which diverge from the older cached form reference.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('menu management goldens', () {
    testWidgets('menu-saya', (tester) async {
      await _pump(tester, const MenuSayaScreen(), size: const Size(390, 844));
      await expectLater(
        find.byType(MenuSayaScreen),
        matchesGoldenFile('goldens/menu_saya.png'),
      );
    }, tags: 'golden');

    testWidgets('menu-saya-2', (tester) async {
      await _pump(tester, const MenuSayaScreen(), size: const Size(390, 844));
      await expectLater(
        find.byType(MenuSayaScreen),
        matchesGoldenFile('goldens/menu_saya_2.png'),
      );
    }, tags: 'golden');

    testWidgets('menu-berhasil-ditambahkan', (tester) async {
      await _pump(
        tester,
        const MenuSayaScreen(recentlyAdded: true),
        size: const Size(390, 844),
      );
      await expectLater(
        find.byType(MenuSayaScreen),
        matchesGoldenFile('goldens/menu_berhasil_ditambahkan.png'),
      );
    }, tags: 'golden');

    testWidgets('tambah-menu', (tester) async {
      await _pump(
        tester,
        const TambahMenuScreen(),
        size: const Size(390, 1382),
      );
      await expectLater(
        find.byType(TambahMenuScreen),
        matchesGoldenFile('goldens/tambah_menu.png'),
      );
    }, tags: 'golden');

    testWidgets('menu-diisi', (tester) async {
      await _pump(
        tester,
        const TambahMenuScreen(prefilled: true),
        size: const Size(390, 1382),
      );
      await expectLater(
        find.byType(TambahMenuScreen),
        matchesGoldenFile('goldens/menu_diisi.png'),
      );
    }, tags: 'golden');

    testWidgets('kelola-menu', (tester) async {
      await _pump(
        tester,
        Scaffold(
          backgroundColor: Colors.white,
          body: Align(
            alignment: Alignment.topCenter,
            child: KelolaMenuSheet(
              onTambahMenu: () {},
              onKelolaVarian: () {},
            ),
          ),
        ),
        size: const Size(390, 380),
      );
      await expectLater(
        find.byType(KelolaMenuSheet),
        matchesGoldenFile('goldens/kelola_menu.png'),
      );
    }, tags: 'golden');

    testWidgets('kelola-menu-2', (tester) async {
      await _pump(
        tester,
        Scaffold(
          backgroundColor: Colors.white,
          body: Align(
            alignment: Alignment.topCenter,
            child: KelolaMenuSheet(
              onTambahMenu: () {},
              onKelolaVarian: () {},
            ),
          ),
        ),
        size: const Size(390, 380),
      );
      await expectLater(
        find.byType(KelolaMenuSheet),
        matchesGoldenFile('goldens/kelola_menu_2.png'),
      );
    }, tags: 'golden');

    testWidgets('berhasil-ditambahkan', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: MenuSuccessModal()),
        ),
        size: const Size(390, 320),
      );
      await expectLater(
        find.byType(MenuSuccessModal),
        matchesGoldenFile('goldens/berhasil_ditambahkan.png'),
      );
    }, tags: 'golden');
  });
}
