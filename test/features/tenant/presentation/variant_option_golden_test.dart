import 'package:dtw_app/features/tenant/presentation/screens/tambah_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/opsi_varian_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for the tenant variant OPTION flow (Part B): the
/// `tambah-opsi-2` / `opsi-2-ditambahkan` variant-form-with-options screens and
/// the 358×262 `opsi-varian-1*` option modals.
///
/// NOTE: like the other tenant self-goldens, the headless harness renders text
/// as Ahem boxes (Open Sans is not bundled), so these pin layout/structure/
/// colours against regressions rather than pixel-diffing the Figma references;
/// fidelity vs. each `.ftk/figma/.../reference.png` was confirmed separately
/// during the build (see the work-item report).
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
      child: MaterialApp(debugShowCheckedModeBanner: false, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Wraps a 358-wide modal on a grey backdrop so its bounds are visible.
Widget _modalHost(Widget modal) => ColoredBox(
      color: const Color(0xFFECECEC),
      child: Center(child: modal),
    );

void main() {
  group('variant option goldens', () {
    testWidgets('tambah-opsi-2 (form + one option)', (tester) async {
      await _pump(
        tester,
        const TambahVarianScreen(
          prefilled: true,
          options: [VariantOptionData(name: 'Small')],
          onSave: _noop,
        ),
        size: const Size(390, 844),
      );
      await expectLater(
        find.byType(TambahVarianScreen),
        matchesGoldenFile('goldens/tambah_opsi_2.png'),
      );
    }, tags: 'golden');

    testWidgets('opsi-2-ditambahkan (form + two options)', (tester) async {
      await _pump(
        tester,
        const TambahVarianScreen(
          prefilled: true,
          options: [
            VariantOptionData(name: 'Small'),
            VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
          ],
          onSave: _noop,
        ),
        size: const Size(390, 844),
      );
      await expectLater(
        find.byType(TambahVarianScreen),
        matchesGoldenFile('goldens/opsi_2_ditambahkan.png'),
      );
    }, tags: 'golden');

    testWidgets('opsi-varian-1 (empty modal)', (tester) async {
      await _pump(
        tester,
        _modalHost(const OpsiVarianModal()),
        size: const Size(390, 300),
      );
      await expectLater(
        find.byType(OpsiVarianModal),
        matchesGoldenFile('goldens/opsi_varian_1.png'),
      );
    }, tags: 'golden');

    testWidgets('opsi-varian-1-diisi (Small / 0)', (tester) async {
      await _pump(
        tester,
        _modalHost(
          const OpsiVarianModal(initialName: 'Small', initialPrice: '0'),
        ),
        size: const Size(390, 300),
      );
      await expectLater(
        find.byType(OpsiVarianModal),
        matchesGoldenFile('goldens/opsi_varian_1_diisi.png'),
      );
    }, tags: 'golden');

    testWidgets('opsi-varian-2-diisi (empty modal)', (tester) async {
      await _pump(
        tester,
        _modalHost(const OpsiVarianModal()),
        size: const Size(390, 300),
      );
      await expectLater(
        find.byType(OpsiVarianModal),
        matchesGoldenFile('goldens/opsi_varian_2_diisi.png'),
      );
    }, tags: 'golden');

    testWidgets('opsi-varian-2-diisi-2 (Medium / 3000)', (tester) async {
      await _pump(
        tester,
        _modalHost(
          const OpsiVarianModal(initialName: 'Medium', initialPrice: '3000'),
        ),
        size: const Size(390, 300),
      );
      await expectLater(
        find.byType(OpsiVarianModal),
        matchesGoldenFile('goldens/opsi_varian_2_diisi_2.png'),
      );
    }, tags: 'golden');
  });
}

void _noop() {}
