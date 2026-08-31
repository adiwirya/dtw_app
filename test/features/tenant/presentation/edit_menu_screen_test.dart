import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/screens/menu_saya_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/routed_dio.dart';
import '../../../support/tenant_board.dart';

const _productId = 'product-7';

/// `GET /v1/products/{id}` — the product being edited. Deliberately inactive
/// at brand level, so a test can prove the PUT carries that through instead of
/// hardcoding `true`.
Map<String, dynamic> _editableProduct({bool isActive = false}) => {
  ...productJson(id: _productId, name: 'Kopi Susu', totalPrice: 18000),
  'category_id': 'cat-2',
  'description': 'Pakai gula aren',
  'is_active': isActive,
};

/// One `GET /v1/products/{id}/modifier-groups` item.
Map<String, dynamic> _attachedGroup(String id, String name) => {
  'id': id,
  'brand_id': 'brand-1',
  'brand_name': 'Janji Jiwa',
  'name': name,
  'description': null,
  'is_required': true,
  'min_selections': 1,
  'max_selections': 1,
  'sequence_order': 1,
  'is_active': true,
  'option_count': 2,
  'created_at': '2026-08-13 11:01:33',
  'updated_at': '2026-08-13 11:01:33',
};

Future<RoutedAdapter> _pumpForm(
  WidgetTester tester, {
  List<Map<String, dynamic>> attached = const [],
  bool isActive = false,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = routedDio({
    'GET /v1/products/$_productId/modifier-groups': (
      200,
      tenantEnvelope(attached),
    ),
    'PUT /v1/products/$_productId': (
      200,
      tenantEnvelope(_editableProduct(isActive: isActive)),
    ),
    'GET /v1/products/$_productId': (
      200,
      tenantEnvelope(_editableProduct(isActive: isActive)),
    ),
    '/v1/product-categories': (
      200,
      tenantEnvelope([
        productCategoryJson(id: 'cat-1', name: 'Nasi'),
        productCategoryJson(id: 'cat-2', name: 'Minuman'),
      ]),
    ),
    '/v1/products': (
      200,
      tenantEnvelope([_editableProduct(isActive: isActive)]),
    ),
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentTenantBranchProvider.overrideWith(
          (ref) async => tenantBranchFixture(),
        ),
        productRepositoryProvider.overrideWithValue(
          ProductRepository(dio: dio),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  const TambahMenuScreen(editingProductId: _productId),
            ),
            GoRoute(
              path: '/berhasil',
              name: TenantRoutes.menuBerhasil,
              builder: (_, _) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: '/kelola-varian',
              name: TenantRoutes.kelolaVarian,
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dio.httpClientAdapter as RoutedAdapter;
}

/// Drains `showMenuSuccessModal`'s 1.4s auto-dismiss timer — a test that
/// leaves it running fails with "A Timer is still pending".
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
  group('the form loads the product being edited', () {
    testWidgets('seeds name, price, category and note from the API', (
      tester,
    ) async {
      await _pumpForm(tester);

      // The nav bar says Ubah, not Tambah.
      expect(find.text('Ubah Menu'), findsOneWidget);
      expect(find.text('Tambah Menu'), findsNothing);

      expect(find.text('Kopi Susu'), findsOneWidget);
      expect(find.text('18000'), findsOneWidget);
      expect(find.text('Pakai gula aren'), findsOneWidget);
      // Category resolved to its name, not left on the hint.
      expect(find.text('Minuman'), findsWidgets);
      expect(find.text('Pilih Kategori'), findsNothing);
      // None of the old `menu-diisi` prototype seed.
      expect(find.text('Paket Komplit'), findsNothing);
    });

    testWidgets('shows the variants already attached to the product', (
      tester,
    ) async {
      await _pumpForm(
        tester,
        attached: [_attachedGroup('group-1', 'Tingkat Pedas')],
      );

      expect(find.text('(1)'), findsOneWidget);
      expect(find.text('Tingkat Pedas'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('PUTs to the product, not POSTing a new one', (tester) async {
      final adapter = await _pumpForm(tester);

      await _tapSimpan(tester);

      final write = adapter.requests.lastWhere(
        (r) => r.method == 'PUT' || r.method == 'POST',
      );
      expect(write.method, 'PUT');
      expect(write.path, '/v1/products/$_productId');
      expect(write.data, {
        'category_id': 'cat-2',
        'name': 'Kopi Susu',
        'price': 18000,
        // Carried through from the fetched product — hardcoding `true` here
        // would silently reactivate a product the tenant had turned off.
        'is_active': false,
        'description': 'Pakai gula aren',
      });
      expect(
        adapter.requests.where(
          (r) => r.method == 'POST' && r.path == '/v1/products',
        ),
        isEmpty,
      );

      // The add frame's copy would tell the tenant their edit was "added".
      expect(find.text(MenuSuccessModal.savedMessage), findsOneWidget);
      expect(find.text(MenuSuccessModal.addedMessage), findsNothing);

      await _drainSuccessModal(tester);
    });

    // `price` on POST/PUT is the tax-inclusive figure the customer pays —
    // the same number `total_price` returns. The fixture's `dpp_price` is
    // 18000/1.11 = 16216, so seeding or sending the pre-tax base instead
    // would shave 11% off the menu on every edit.
    testWidgets('sends the tax-inclusive price, not the pre-tax base', (
      tester,
    ) async {
      final adapter = await _pumpForm(tester);

      await _tapSimpan(tester);

      final put = adapter.requests.lastWhere((r) => r.method == 'PUT');
      expect((put.data! as Map)['price'], 18000);
      // What the form displayed is what it sent.
      expect(find.text('18000'), findsOneWidget);
      expect(find.text('16216'), findsNothing);

      await _drainSuccessModal(tester);
    });

    testWidgets('an active product stays active', (tester) async {
      final adapter = await _pumpForm(tester, isActive: true);

      await _tapSimpan(tester);

      final put = adapter.requests.lastWhere((r) => r.method == 'PUT');
      expect((put.data! as Map)['is_active'], isTrue);

      await _drainSuccessModal(tester);
    });

    // `syncModifierGroups` is a full replace, so an edit that saved with an
    // empty selection would silently detach everything the product had.
    testWidgets('re-syncs the variants it loaded', (tester) async {
      final adapter = await _pumpForm(
        tester,
        attached: [_attachedGroup('group-1', 'Tingkat Pedas')],
      );

      await _tapSimpan(tester);

      final sync = adapter.requests.lastWhere(
        (r) => r.path.contains('modifier-groups/sync'),
      );
      expect(sync.data, {
        'modifier_group_ids': ['group-1'],
      });

      await _drainSuccessModal(tester);
    });
  });

  // Regression test: `MenuItemCard.onTap` navigated to a parameterless
  // `menu-diisi`, which rendered the form on a hardcoded "Paket Komplit".
  testWidgets('tapping a Menu Saya row opens that product', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MenuSayaScreen()),
        GoRoute(
          path: '/diisi/:productId',
          name: TenantRoutes.menuDiisi,
          builder: (context, state) =>
              Text('edit:${state.pathParameters['productId']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: tenantMenuOverrides(
          products: [
            productJson(id: 'p1', name: 'Sahabat Latte'),
            productJson(id: 'p2', name: 'Kopi Susu'),
          ],
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MenuItemCard, 'Kopi Susu'));
    await tester.pumpAndSettle();

    expect(find.text('edit:p2'), findsOneWidget);
  });

  test('MenuVariantSelection is what carries attachments across screens', () {
    // Guards the contract the edit form depends on: the picker reads this to
    // pre-tick, and the form reads it to sync.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(menuVariantSelectionProvider), isEmpty);
  });
}
