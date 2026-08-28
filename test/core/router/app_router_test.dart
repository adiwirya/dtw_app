import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('homePathFor', () {
    test('tenant_keeper lands on the tenant shell', () {
      expect(
        homePathFor(role: AuthRoles.tenantKeeper, branchId: 'branch-1'),
        TenantRoutes.orderPath,
      );
    });

    test('busboy lands on the busboy shell', () {
      expect(
        homePathFor(role: AuthRoles.busboy, branchId: null),
        AppRoutes.orderPath,
      );
    });

    // The whole point of the switch: the role decides, not the scope.
    test('the role wins when it disagrees with the branch scope', () {
      // A branch scope used to force the tenant shell on its own.
      expect(
        homePathFor(role: AuthRoles.busboy, branchId: 'branch-1'),
        AppRoutes.orderPath,
      );
      // And its absence used to force busboy.
      expect(
        homePathFor(role: AuthRoles.tenantKeeper, branchId: null),
        TenantRoutes.orderPath,
      );
    });

    group('an unrecognised role falls back to the scope', () {
      test('null role with a branch scope goes to tenant', () {
        expect(
          homePathFor(role: null, branchId: 'branch-1'),
          TenantRoutes.orderPath,
        );
      });

      test('null role without a branch scope goes to busboy', () {
        expect(homePathFor(role: null, branchId: null), AppRoutes.orderPath);
      });

      // A role this build has never seen must not be guessed at — it lands on
      // whichever shell the session's real scope data can serve.
      test('an unknown role defers to the scope', () {
        expect(
          homePathFor(role: 'cashier', branchId: 'branch-1'),
          TenantRoutes.orderPath,
        );
        expect(
          homePathFor(role: 'cashier', branchId: null),
          AppRoutes.orderPath,
        );
      });
    });
  });
}
