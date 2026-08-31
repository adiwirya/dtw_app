import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/screens/menu_saya_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_success_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/routed_dio.dart';
import '../../../support/tenant_board.dart';

/// The one category the form can pick.
const _categoryId = 'cat-1';

/// A picked variant, as `PilihVarianScreen` would hand it over.
const _pickedVariant = VariantData(
  id: 'group-1',
  name: 'Level Kepedasan',
  type: VariantType.tunggal,
  optionCount: 2,
);

/// Seeds [MenuVariantSelection] so a test can stand in for the picker.
class _SeededSelection extends MenuVariantSelection {
  _SeededSelection(this.seed);

  final List<VariantData> seed;

  @override
  List<VariantData> build() => seed;
}

/// Pumps the add-menu form behind a router (the success modal's `onConfirm`
/// navigates to `menu-berhasil-ditambahkan`), returning the routed adapter so
/// a test can assert exactly which calls the save made.
Future<RoutedAdapter> _pump(
  WidgetTester tester, {
  List<VariantData> picked = const [],
  int syncStatus = 200,
  int createStatus = 201,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = routedDio({
    'POST /v1/products/': (syncStatus, tenantEnvelope(null)),
    'POST /v1/products': (
      createStatus,
      createStatus >= 400
          ? {
              'meta': {
                'success': false,
                'message': 'Validation failed.',
                'code': createStatus,
                'trace_id': 'abc',
              },
              'errors': {
                'name': ['The name field is required.'],
              },
            }
          : tenantEnvelope(
              productJson(id: 'product-9', name: 'Paket Komplit',
                  totalPrice: 32000),
            ),
    ),
    '/v1/product-categories': (
      200,
      tenantEnvelope([productCategoryJson(id: _categoryId, name: 'Nasi')]),
    ),
    '/v1/products': (200, tenantEnvelope(<dynamic>[])),
  });

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const TambahMenuScreen()),
      GoRoute(
        path: '/berhasil',
        name: TenantRoutes.menuBerhasil,
        builder: (_, _) => const MenuSayaScreen(recentlyAdded: true),
      ),
      GoRoute(
        path: '/kelola-varian',
        name: TenantRoutes.kelolaVarian,
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentTenantBranchProvider.overrideWith(
          (ref) async => tenantBranchFixture(),
        ),
        productRepositoryProvider.overrideWithValue(
          ProductRepository(dio: dio),
        ),
        menuVariantSelectionProvider.overrideWith(
          () => _SeededSelection(picked),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return dio.httpClientAdapter as RoutedAdapter;
}

/// Picks the one seeded category.
///
/// Taps the `DropdownButton` itself, not its hint `Text`: the hint is painted
/// inside the button and is not independently hit-testable, and
/// `DropdownButton` also builds every item offstage for sizing — so
/// `find.text('Nasi')` matches even while the menu is closed.
Future<void> _pickCategory(WidgetTester tester) async {
  final dropdown = find.byType(DropdownButton<String>);
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nasi').last);
  await tester.pumpAndSettle();
}

Future<void> _fillForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Paket Komplit');
  await _pickCategory(tester);
  // The Harga field is the second TextField on the form (after Nama Menu).
  await tester.enterText(find.byType(TextField).at(1), '32.000');
  await tester.pumpAndSettle();
}

/// Drains `showMenuSuccessModal`'s 1.4s auto-dismiss timer.
///
/// The modal closes itself on a `Timer`, so a test that leaves it open fails
/// with "A Timer is still pending even after the widget tree was disposed".
/// Call this after asserting on the modal.
Future<void> _drainSuccessModal(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

Future<void> _tapSimpan(WidgetTester tester) async {
  final simpan = find.widgetWithText(PrimaryButton, 'Simpan Menu');
  await tester.ensureVisible(simpan);
  await tester.pumpAndSettle();
  await tester.tap(simpan);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Kategori dropdown offers the fetched categories',
      (tester) async {
    await _pump(tester);

    // Starts on the hint, i.e. no category chosen.
    expect(find.text('Pilih Kategori'), findsOneWidget);

    await _pickCategory(tester);

    // The hint is replaced by the selection.
    expect(find.text('Pilih Kategori'), findsNothing);
    expect(find.text('Nasi'), findsWidgets);
  });

  group('validation (nothing is sent until the form is valid)', () {
    testWidgets('an empty name is rejected', (tester) async {
      final adapter = await _pump(tester);

      await _tapSimpan(tester);

      expect(find.text('Nama menu wajib diisi.'), findsOneWidget);
      expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
    });

    testWidgets('a missing category is rejected', (tester) async {
      final adapter = await _pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Paket Komplit');
      await _tapSimpan(tester);

      expect(find.text('Kategori wajib dipilih.'), findsOneWidget);
      expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
    });

    testWidgets('a zero price is rejected', (tester) async {
      final adapter = await _pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Paket Komplit');
      await _pickCategory(tester);
      await _tapSimpan(tester);

      expect(find.text('Harga wajib diisi.'), findsOneWidget);
      expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
    });
  });

  testWidgets('Simpan Menu POSTs the product and raises the success modal',
      (tester) async {
    final adapter = await _pump(tester);

    await _fillForm(tester);
    await _tapSimpan(tester);

    final post = adapter.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/products');
    expect(post.data, {
      'brand_id': 'brand-1',
      'category_id': _categoryId,
      'name': 'Paket Komplit',
      // `32.000` is parsed with parseRupiah, so the dot is not sent.
      'price': 32000,
    });
    expect(find.byType(MenuSuccessModal), findsOneWidget);

    await _drainSuccessModal(tester);
  });

  testWidgets('a failed create shows the mapped message and does not advance',
      (tester) async {
    await _pump(tester, createStatus: 422);

    await _fillForm(tester);
    await _tapSimpan(tester);

    expect(find.text('The name field is required.'), findsOneWidget);
    expect(find.byType(MenuSuccessModal), findsNothing);
    expect(find.byType(TambahMenuScreen), findsOneWidget);
  });

  group('attached variants', () {
    testWidgets('the picked variants are previewed on the form',
        (tester) async {
      await _pump(tester, picked: const [_pickedVariant]);

      expect(find.text('(1)'), findsOneWidget);
      expect(find.text('Level Kepedasan'), findsOneWidget);
      // The picker's list endpoint knows the count but not the option names.
      expect(find.text('2 Opsi'), findsOneWidget);
    });

    testWidgets('saving syncs them to the created product', (tester) async {
      final adapter = await _pump(tester, picked: const [_pickedVariant]);

      await _fillForm(tester);
      await _tapSimpan(tester);

      final sync = adapter.requests.last;
      expect(sync.method, 'POST');
      expect(sync.path, '/v1/products/product-9/modifier-groups/sync');
      expect(sync.data, {'modifier_group_ids': ['group-1']});
      expect(find.byType(MenuSuccessModal), findsOneWidget);

      await _drainSuccessModal(tester);
    });

    testWidgets('nothing is synced when no variant was picked',
        (tester) async {
      final adapter = await _pump(tester);

      await _fillForm(tester);
      await _tapSimpan(tester);

      expect(
        adapter.requests.where((r) => r.path.contains('modifier-groups')),
        isEmpty,
      );

      await _drainSuccessModal(tester);
    });

    // The menu is already created by the time the sync runs, so a sync failure
    // must not read as "the menu wasn't saved".
    testWidgets('a failed sync still reports the menu as saved',
        (tester) async {
      await _pump(tester, picked: const [_pickedVariant], syncStatus: 500);

      await _fillForm(tester);
      await _tapSimpan(tester);

      expect(find.textContaining('Menu tersimpan, varian gagal'),
          findsOneWidget);
      expect(find.byType(MenuSuccessModal), findsOneWidget);

      await _drainSuccessModal(tester);
    });
  });
}
