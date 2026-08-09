import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/akun/data/models/akun_account.dart';
import 'package:dtw_app/features/akun/presentation/providers/akun_provider.dart';
import 'package:dtw_app/features/akun/presentation/widgets/account_menu_tile.dart';
import 'package:dtw_app/features/akun/presentation/widgets/akun_header.dart';
import 'package:dtw_app/features/akun/presentation/widgets/profile_summary_card.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `akun` frame: the Account-tab home. A green header over a white body
/// with a floating profile/stats card and a grouped account menu that links to
/// Profil Saya. Hosted inside the app shell, so the bottom nav is provided by
/// `AppShell`.
class AkunScreen extends ConsumerWidget {
  const AkunScreen({super.key});

  void _onMenuTap(BuildContext context, AccountMenuItem item) {
    final route = item.routeName;
    if (route != null) {
      context.goNamed(route);
      return;
    }
    // TODO(open-question): unresolved account action — Ubah Kata Sandi,
    // Bahasa, Bantuan & FAQ, Kebijakan Privasi have no destination flow yet.
  }

  Future<void> _onLogout(WidgetRef ref) {
    return ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(akunAccountProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AkunHeader(),
          Expanded(
            child: Container(
              // Pull the white body up so the profile card overlaps the green
              // header band (the card's rounded top sits inside the green).
              transform: Matrix4.translationValues(0, -34, 0),
              color: AppColors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  ProfileSummaryCard(account: account),
                  const SizedBox(height: 16),
                  _MenuCard(
                    account: account,
                    onItemTap: (item) => _onMenuTap(context, item),
                    onLogout: () => _onLogout(ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The white rounded card grouping the account menu rows over a hairline and
/// the destructive logout row (`Frame 2617`).
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.account,
    required this.onItemTap,
    required this.onLogout,
  });

  final AkunAccount account;
  final ValueChanged<AccountMenuItem> onItemTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          for (var i = 0; i < account.menuItems.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            AccountMenuTile(
              item: account.menuItems[i],
              onTap: () => onItemTap(account.menuItems[i]),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ),
          AccountMenuTile(item: account.logoutItem, onTap: onLogout),
        ],
      ),
    );
  }
}
