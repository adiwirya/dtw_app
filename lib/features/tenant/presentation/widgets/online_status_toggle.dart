import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The admin "Status Tenant" card with the online/offline action button
/// (`admin-online` / `admin-offline`).
///
/// When [online] is true the card shows a green `ONLINE` heading, the
/// customer-visible description and a red "Set Offline" button; when false it
/// shows a red `OFFLINE` heading and a green "Set Online" button. [onToggle] is
/// invoked with the requested new state.
///
/// Copy defaults match the design; override [onlineDescription] /
/// [offlineDescription] if needed.
class OnlineStatusToggle extends StatelessWidget {
  const OnlineStatusToggle({
    required this.online,
    required this.onToggle,
    this.onlineDescription =
        'Customer dapat melihat menu dan melakukan pemesanan di tenant Anda',
    this.offlineDescription = 'Customer tidak dapat melihat menu dan '
        'melakukan pemesanan di tenant Anda',
    super.key,
  });

  /// Whether the tenant is currently online.
  final bool online;

  /// Called with the requested new state (`!online`) when the button is tapped.
  final ValueChanged<bool> onToggle;

  /// Description shown in the online state.
  final String onlineDescription;

  /// Description shown in the offline state.
  final String offlineDescription;

  static const double _radius = 12;

  Color get _accent => online ? AppColors.successGreen : AppColors.dangerRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
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
          const Text(
            'Status Tenant',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _statusBlock(),
          const SizedBox(height: 16),
          _actionButton(),
        ],
      ),
    );
  }

  Widget _statusBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: online ? AppColors.successTint : AppColors.dangerTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.power_settings_new, size: 20, color: _accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                online ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                online ? onlineDescription : offlineDescription,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton() {
    // Set Offline (red) when online; Set Online (green) when offline.
    final color = online ? AppColors.dangerRed : AppColors.successGreen;
    final label = online ? 'Set Offline' : 'Set Online';
    final radius = BorderRadius.circular(100);
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          onTap: () => onToggle(!online),
          borderRadius: radius,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.power_settings_new,
                    size: 18, color: AppColors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
