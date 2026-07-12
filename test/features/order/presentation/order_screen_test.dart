import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A board notifier whose Antar sub-tab starts empty (empty-state test).
class _EmptyAntarBoard extends OrderBoardNotifier {
  @override
  OrderBoard build() {
    final full = super.build();
    return full.copyWith(antar: const []);
  }
}

Widget _wrap({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: OrderScreen()),
  );
}

void main() {
  testWidgets('renders the three sub-tabs from the segmented bar',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedTabBar), findsOneWidget);
    expect(find.text('Ambil'), findsOneWidget);
    expect(find.text('Antar'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('Baru sub-tab shows the populated order list', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(find.text('KFC Fried Chicken'), findsOneWidget);
    // Baru cards expose the Detail affordance, no action button.
    expect(find.text('Detail'), findsNWidgets(2));
    expect(find.text('Sampai dimeja'), findsNothing);
  });

  testWidgets('switching to Antar shows the deliver action button',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antar'));
    await tester.pumpAndSettle();

    expect(find.text('Sampai dimeja'), findsNWidgets(2));
  });

  testWidgets('an empty sub-tab renders the empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          orderBoardNotifierProvider.overrideWith(_EmptyAntarBoard.new),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antar'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderEmptyState), findsOneWidget);
    expect(find.byType(OrderCard), findsNothing);
  });

  testWidgets(
      'delivering an Antar order raises the success modal and moves it to '
      'Selesai on confirm', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sampai dimeja').first);
    await tester.pumpAndSettle();

    // The shared success modal (berhasil-ditambahkan-2 copy) is shown.
    expect(find.byType(SuccessModal), findsOneWidget);
    expect(find.text('Sampai dimeja'), findsWidgets); // modal title
    expect(find.text('Lanjutkan'), findsOneWidget);

    // Confirm: modal pops and the Selesai sub-tab is now selected.
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.byType(SuccessModal), findsNothing);
    // Selesai now has the original delivered order + the just-delivered one.
    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(find.text('Diantar pada'), findsNWidgets(2));
  });
}
