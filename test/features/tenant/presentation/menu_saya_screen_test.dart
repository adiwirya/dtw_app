import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/features/tenant/presentation/screens/menu_saya_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/tenant_board.dart';

/// Two active menus and one inactive one, so every status pill has a distinct
/// expected result.
List<Map<String, dynamic>> _products() => [
  productJson(id: 'p1', name: 'Sahabat Latte'),
  productJson(id: 'p2', name: 'Sahabat Hazelnut', totalPrice: 21000),
  productJson(id: 'p3', name: 'Kopi Susu', totalPrice: 18000),
];

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: tenantMenuOverrides(
        products: _products(),
        availability: const {'p1': true, 'p2': true, 'p3': false},
      ),
      child: const MaterialApp(home: MenuSayaScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// The pills sit in a horizontal `ListView` and Ahem text is wide enough to
/// push the trailing ones past the 390px design width — scroll before tapping
/// or `tap` derives an offset outside the render tree and misses.
Future<void> _tapPill(WidgetTester tester, String label) async {
  final pill = find.text(label);
  await tester.ensureVisible(pill);
  await tester.pumpAndSettle();
  await tester.tap(pill);
  await tester.pumpAndSettle();
}

void main() {
  // The design frame had five pills (Semua/Aktif/Habis/Promo/Best Seller) with
  // hardcoded counts and no filtering. Only the active/inactive split has
  // backing data, so the set is reduced to what the API can actually support.
  testWidgets('the status pills carry real counts derived from the list',
      (tester) async {
    await _pump(tester);

    expect(find.text('Semua (3)'), findsOneWidget);
    expect(find.text('Aktif (2)'), findsOneWidget);
    expect(find.text('Nonaktif (1)'), findsOneWidget);
    // The three pills with no API concept behind them are gone.
    expect(find.textContaining('Habis'), findsNothing);
    expect(find.textContaining('Promo'), findsNothing);
    expect(find.textContaining('Best Seller'), findsNothing);
  });

  testWidgets('Semua lists every menu', (tester) async {
    await _pump(tester);
    expect(find.byType(MenuItemCard), findsNWidgets(3));
  });

  testWidgets('Aktif lists only the available menus', (tester) async {
    await _pump(tester);

    await _tapPill(tester, 'Aktif (2)');

    expect(find.byType(MenuItemCard), findsNWidgets(2));
    expect(find.text('Kopi Susu'), findsNothing);
  });

  testWidgets('Nonaktif lists only the unavailable menus', (tester) async {
    await _pump(tester);

    await _tapPill(tester, 'Nonaktif (1)');

    expect(find.byType(MenuItemCard), findsOneWidget);
    expect(find.text('Kopi Susu'), findsOneWidget);
  });

  testWidgets('search narrows the list by name', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).first, 'hazelnut');
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemCard), findsOneWidget);
    expect(find.text('Sahabat Hazelnut'), findsOneWidget);
  });

  testWidgets('search and the status pill compose', (tester) async {
    await _pump(tester);

    await _tapPill(tester, 'Aktif (2)');
    await tester.enterText(find.byType(TextField).first, 'kopi');
    await tester.pumpAndSettle();

    // "Kopi Susu" matches the name but is inactive, so Aktif excludes it.
    expect(find.byType(MenuItemCard), findsNothing);
    expect(find.text('Menu tidak ditemukan.'), findsOneWidget);
  });

  // Regression guard: `MenuList.setActive` addresses the provider list by
  // position, so a filtered row index would flip the WRONG product. Here the
  // only visible row is the list's third product.
  testWidgets('the toggle targets the right product while filtered',
      (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).first, 'kopi');
    await tester.pumpAndSettle();

    // Only "Kopi Susu" (p3, inactive) is showing.
    expect(find.byType(MenuItemCard), findsOneWidget);
    expect(find.text('Nonaktif'), findsOneWidget);

    await tester.tap(find.byType(AppToggle));
    await tester.pumpAndSettle();

    // p3 flipped, not p1: clearing the search shows all three active, so the
    // pill counts move to 3/0 rather than staying at 2/1.
    expect(find.text('Aktif'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemCard), findsNWidgets(3));
    expect(find.text('Aktif (3)'), findsOneWidget);
    expect(find.text('Nonaktif (0)'), findsOneWidget);
  });
}
