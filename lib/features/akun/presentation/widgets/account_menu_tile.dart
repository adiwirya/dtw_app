import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/akun/data/models/akun_account.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// One row in the account menu (`Frame 2612` + `Icon / chevron-right`): a round
/// icon chip, a title over a grey subtitle, and a trailing chevron. Destructive
/// rows (the logout row) tint the chip and title red and drop the chevron.
class AccountMenuTile extends StatelessWidget {
  const AccountMenuTile({required this.item, required this.onTap, super.key});

  final AccountMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destructive = item.destructive;
    final chipColor =
        destructive ? AppColors.dangerTint : AppColors.neutralTint;
    final iconColor =
        destructive ? AppColors.dangerRed : AppColors.neutral500;
    final titleColor =
        destructive ? AppColors.dangerRed : AppColors.neutral900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        label: item.title,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    // TODO(open-question): Open Sans Bold cache font unbundled.
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (!destructive) ...[
              const SizedBox(width: 8),
              const Icon(
                ObraIcons.chevron_right,
                size: 20,
                color: AppColors.neutral300,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
