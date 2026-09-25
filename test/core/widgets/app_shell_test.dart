import 'package:dtw_app/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A minimal 2-branch shell router — just enough to exercise
/// [AppShell]'s tab-switch and re-tap-pops-to-root behavior without
/// depending on the real `app_router.dart` wiring.
GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/tab0',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab0',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tab0 root')),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) =>
                        const Scaffold(body: Text('Tab0 detail')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab1',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tab1 root')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: _testRouter()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a different tab switches to its branch', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Tab0 root'), findsOneWidget);

    await tester.tap(find.text('Performa'));
    await tester.pumpAndSettle();

    expect(find.text('Tab1 root'), findsOneWidget);
    expect(find.text('Tab0 root'), findsNothing);
  });

  testWidgets('re-tapping the active tab pops it back to its root', (
    tester,
  ) async {
    await _pump(tester);
    // Push a detail screen inside the active tab's own stack.
    final context = tester.element(find.text('Tab0 root'));
    GoRouter.of(context).go('/tab0/detail');
    await tester.pumpAndSettle();
    expect(find.text('Tab0 detail'), findsOneWidget);

    // Re-tap the same (still active) tab.
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();

    expect(find.text('Tab0 root'), findsOneWidget);
    expect(find.text('Tab0 detail'), findsNothing);
  });
}
