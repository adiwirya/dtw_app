import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The green gradient header shared by `performa-v1` and `performa-v2`:
/// a white iOS status bar over an avatar + greeting row. The white body panel
/// is drawn by the screen and overlaps the bottom of this band via its rounded
/// top corners.
class PerformaHeader extends StatelessWidget {
  const PerformaHeader({required this.greeting, super.key});

  final PerformaGreeting greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: Column(
        children: [
          // The OS draws the real status bar here; the header runs behind
          // it. A fake `9:41` bar used to sit in this slot, doubling up with
          // the real one on device.
          SizedBox(height: MediaQuery.paddingOf(context).top),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GreetingRow(greeting: greeting),
          ),
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.greeting});

  final PerformaGreeting greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO(open-question): the avatar raster ("ChatGPT Image ..." 40x40)
        // was not exported to the asset cache; using a tinted placeholder.
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.successTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 24,
            color: AppColors.success700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi, ${greeting.name} 👋',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
