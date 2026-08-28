import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// Top block of the `laporan` frame: iOS status bar, the "Laporan" title with
/// an "Export" action, the tenant / table subtitle, and the period filter
/// chips (Semua / Hari / …).
class LaporanHeader extends StatelessWidget {
  const LaporanHeader({
    required this.tenantName,
    required this.tableLabel,
    required this.filters,
    required this.activeFilter,
    super.key,
  });

  final String tenantName;
  final String tableLabel;
  final List<String> filters;
  final int activeFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DarkStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Laporan',
                      // bundled (mirrors the busboy Performa TODO).
                      style: TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ObraIcons.cloud_download,
                        size: 18,
                        color: AppColors.successGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Export',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      tenantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.neutral300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    tableLabel,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 35,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _FilterChip(
              label: filters[i],
              selected: i == activeFilter,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? AppColors.successGreen : AppColors.neutralTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.white : AppColors.neutral500,
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

/// Dark-on-white iOS status bar (`9:41` + signal / wifi / battery). Mirrors the
/// project convention of drawing the status bar in-screen (see `LoginStatusBar`
/// / the busboy Performa header) but tinted for a light background.
// TODO(open-question): pixel-exact SVG glyphs are approximated with Material
// icons until flutter_svg is available.
class _DarkStatusBar extends StatelessWidget {
  const _DarkStatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt,
                    size: 17, color: AppColors.neutral900),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 17, color: AppColors.neutral900),
                SizedBox(width: 6),
                Icon(Icons.battery_full,
                    size: 22, color: AppColors.neutral900),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
