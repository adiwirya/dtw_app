import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The pale-green "Insight Hari ini" callout at the bottom of `performa-v2`.
class InsightCard extends StatelessWidget {
  const InsightCard({required this.insight, super.key});

  final PerformaInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO(open-question): the `idea-svgrepo` bulb glyph is approximated
          // with a Material icon until flutter_svg is available.
          const Icon(
            Icons.lightbulb_outline,
            size: 22,
            color: AppColors.success700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    color: AppColors.success700,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.body,
                  style: const TextStyle(
                    color: AppColors.success700,
                    fontSize: 13,
                    height: 1.35,
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
