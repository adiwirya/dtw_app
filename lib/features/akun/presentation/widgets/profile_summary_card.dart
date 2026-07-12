import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/akun/data/models/akun_account.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The white profile card floating over the green header (`Frame 2417` +
/// `Frame 2611`): an avatar + identity row above a bordered three-up stats box.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({required this.account, super.key});

  final AkunAccount account;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _IdentityRow(account: account),
          const SizedBox(height: 16),
          _StatsBox(stats: account.stats),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.account});

  final AkunAccount account;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Avatar(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi, ${account.name}',
                // TODO(open-question): Open Sans Bold cache font not bundled.
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Busboy ID : ${account.busboyId}',
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bergabung ${account.joinedLabel}',
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // TODO(open-question): the avatar raster ("ChatGPT Image ..." 80x80)
          // was not exported to the asset cache; using a tinted placeholder.
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.successTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              ObraIcons.user,
              size: 40,
              color: AppColors.success700,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                ObraIcons.camera,
                size: 14,
                color: AppColors.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bordered stats box: three centred stats split by 1px hairline dividers
/// (`Frame 2611` with `Rectangle 1271/1272`).
class _StatsBox extends StatelessWidget {
  const _StatsBox({required this.stats});

  final List<AccountStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.hairline,
                ),
              Expanded(child: _StatColumn(stat: stats[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stat});

  final AccountStat stat;

  @override
  Widget build(BuildContext context) {
    final valueColor = Color(stat.color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              stat.value,
              // TODO(open-question): Open Sans Bold in the cache; not bundled.
              style: TextStyle(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            if (stat.unit != null) ...[
              const SizedBox(width: 3),
              Text(
                stat.unit!,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
            if (stat.showStar) ...[
              const SizedBox(width: 3),
              const Icon(Icons.star, size: 16, color: AppColors.starAmber),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            stat.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}
