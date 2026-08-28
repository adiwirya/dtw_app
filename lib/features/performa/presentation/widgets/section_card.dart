import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// White rounded surface with the shared card drop-shadow, used for the chart /
/// target / insight blocks on both Performa frames. An optional [title] renders
/// a bold heading above [child].
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    super.key,
  });

  final Widget child;
  final String? title;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
