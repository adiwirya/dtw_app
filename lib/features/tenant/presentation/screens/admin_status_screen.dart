import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/akun/data/models/akun_account.dart';
import 'package:dtw_app/features/akun/presentation/widgets/account_menu_tile.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:dtw_app/features/tenant/presentation/providers/admin_status_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/admin_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';

/// The Admin-tab home: the tenant profile/status screen (`admin-offline` /
/// `admin-online` — both routes render this, see `tenant_router.dart`).
///
/// Hosted in the tenant shell so the bottom nav is provided by `TenantShell`.
class AdminStatusScreen extends ConsumerWidget {
  const AdminStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(tenantAdminInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(errorMessage(error))),
        data: (info) => _buildBody(context, ref, info),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TenantAdminInfo info,
  ) {
    final hasOperationalHours =
        info.operationalHours != null && info.operationalDays != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeroHeader(info: info),
        Expanded(
          child: Container(
            // Pull the white body up so its rounded top overlaps the green
            // hero band (Rectangle 363 in the reference).
            transform: Matrix4.translationValues(0, -24, 0),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                if (hasOperationalHours) ...[
                  _JamOperasionalCard(
                    hours: info.operationalHours!,
                    days: info.operationalDays!,
                  ),
                  const SizedBox(height: 16),
                ],
                _InformasiTenantCard(info: info),
                const SizedBox(height: 16),
                _AkunCard(
                  onLogout: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared white rounded card wrapper matching the Status Tenant card.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Green-tinted 32x32 rounded icon tile used on the info rows.
class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppColors.successGreen),
    );
  }
}

/// `Jam Operasional` card — clock tile + hours span + day cadence. Only ever
/// built once both [hours] and [days] are known (see `AdminStatusScreen`).
class _JamOperasionalCard extends StatelessWidget {
  const _JamOperasionalCard({required this.hours, required this.days});

  final String hours;
  final String days;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Jam Operasional',
      child: Row(
        children: [
          const _IconTile(ObraIcons.clock_3),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  hours,
                  style: const TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.neutral300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    days,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `Informasi Tenant` card — Bergabung Sejak always renders (real API data);
/// Rating / Contact Tenant only render when the API actually has a value for
/// them, with a hairline only between rows that are both visible.
class _InformasiTenantCard extends StatelessWidget {
  const _InformasiTenantCard({required this.info});

  final TenantAdminInfo info;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRow(
        // TODO(open-question): obra_icons has no plain star glyph; the
        // Material star stands in until an SVG is exported.
        icon: ObraIcons.calendar_dates,
        label: 'Bergabung Sejak',
        value: info.joinedLabel,
      ),
      if (info.rating case final rating?)
        _InfoRow(icon: Icons.star, label: 'Rating', value: rating),
      if (info.contact case final contact?)
        _InfoRow(
          icon: ObraIcons.headphones,
          label: 'Contact Tenant',
          value: contact,
        ),
    ];

    return _SectionCard(
      title: 'Informasi Tenant',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const _RowDivider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// `Akun` card — the destructive `Keluar` (logout) row, styled the same as
/// the busboy Akun tab's logout row since the tenant flavor has no dedicated
/// Akun tab of its own.
class _AkunCard extends StatelessWidget {
  const _AkunCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Akun',
      child: AccountMenuTile(
        item: const AccountMenuItem(
          icon: ObraIcons.log_out,
          title: 'Keluar',
          subtitle: 'Keluar dari akun',
          destructive: true,
        ),
        onTap: onLogout,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconTile(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
    );
  }
}
