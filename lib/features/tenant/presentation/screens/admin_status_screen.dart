import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:dtw_app/features/tenant/presentation/providers/admin_status_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/admin_hero_header.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/online_status_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';

/// The Admin-tab home: the store online/offline status screen
/// (`admin-offline` / `admin-online`).
///
/// A single screen drives both states: it watches [AdminOnlineStatus] and the
/// `Set Online` / `Set Offline` button flips the flag **in place** (no
/// navigation), rebuilding the hero pill, the Status Tenant card and its button
/// into the other state. The two router entry points (`/admin`, `/admin/online`)
/// select the starting state via [initialOnline]; hosted in the tenant shell so
/// the bottom nav is provided by `TenantShell`.
class AdminStatusScreen extends ConsumerWidget {
  const AdminStatusScreen({this.initialOnline = false, super.key});

  /// Starting online state for this entry point (`/admin` → false,
  /// `/admin/online` → true).
  final bool initialOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusProvider =
        adminOnlineStatusProvider(initialOnline: initialOnline);
    final online = ref.watch(statusProvider);
    final info = ref.watch(tenantAdminInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeroHeader(info: info, online: online),
          Expanded(
            child: Container(
              // Pull the white body up so its rounded top overlaps the green
              // hero band (Rectangle 363 in the reference).
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  OnlineStatusToggle(
                    online: online,
                    onToggle: (next) =>
                        ref.read(statusProvider.notifier).set(value: next),
                  ),
                  const SizedBox(height: 16),
                  _JamOperasionalCard(info: info),
                  const SizedBox(height: 16),
                  _InformasiTenantCard(info: info),
                ],
              ),
            ),
          ),
        ],
      ),
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

/// `Jam Operasional` card — clock tile + hours span + day cadence.
class _JamOperasionalCard extends StatelessWidget {
  const _JamOperasionalCard({required this.info});

  final TenantAdminInfo info;

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
                  info.operationalHours,
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
                    info.operationalDays,
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

/// `Informasi Tenant` card — Bergabung Sejak / Rating / Contact Tenant rows.
class _InformasiTenantCard extends StatelessWidget {
  const _InformasiTenantCard({required this.info});

  final TenantAdminInfo info;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informasi Tenant',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            // TODO(open-question): obra_icons has no plain star glyph; the
            // Material star stands in until an SVG is exported.
            icon: ObraIcons.calendar_dates,
            label: 'Bergabung Sejak',
            value: info.joinedLabel,
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.star,
            label: 'Rating',
            value: info.rating,
          ),
          const _RowDivider(),
          _InfoRow(
            icon: ObraIcons.headphones,
            label: 'Contact Tenant',
            value: info.contact,
          ),
        ],
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
