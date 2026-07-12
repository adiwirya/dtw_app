import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The "Target Hari Ini" progress block on `performa-v2`: a title / count row,
/// a rounded progress bar, and a supporting caption.
class TargetProgress extends StatelessWidget {
  const TargetProgress({required this.target, super.key});

  final DailyTarget target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Target Hari Ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${target.current}/${target.total} ',
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: target.unit,
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: target.progress,
            minHeight: 12,
            backgroundColor: AppColors.neutral100,
            valueColor:
                const AlwaysStoppedAnimation(AppColors.successGreen),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          target.caption,
          style: const TextStyle(
            color: AppColors.neutral500,
            fontSize: 13,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
