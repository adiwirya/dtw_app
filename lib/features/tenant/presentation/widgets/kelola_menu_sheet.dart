import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// Presents the `kelola-menu` modal as a bottom sheet and completes when it is
/// dismissed. The sheet itself never navigates — [onTambahMenu] / [onKelolaVarian]
/// fire after the sheet pops so the caller owns the destination.
Future<void> showKelolaMenuSheet(
  BuildContext context, {
  required VoidCallback onTambahMenu,
  required VoidCallback onKelolaVarian,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => KelolaMenuSheet(
      onTambahMenu: () {
        Navigator.of(sheetContext).pop();
        onTambahMenu();
      },
      onKelolaVarian: () {
        Navigator.of(sheetContext).pop();
        onKelolaVarian();
      },
    ),
  );
}

/// The `kelola-menu` modal body (`Kelola Menu` 358x245): a title over two equal
/// action cards — "Tambah Menu" and "Kelola Varian".
///
/// Public so it can be pumped directly in golden tests and reused inside the
/// bottom-sheet presentation ([showKelolaMenuSheet]).
class KelolaMenuSheet extends StatelessWidget {
  const KelolaMenuSheet({
    required this.onTambahMenu,
    required this.onKelolaVarian,
    super.key,
  });

  /// Tapped the "Tambah Menu" card (→ the add-menu form).
  final VoidCallback onTambahMenu;

  /// Tapped the "Kelola Varian" card (→ item 07's varian sub-flow).
  final VoidCallback onKelolaVarian;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kelola Menu',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: ObraIcons.document_add,
                    title: 'Tambah Menu',
                    subtitle: 'Buat menu baru untuk dijual',
                    onTap: onTambahMenu,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    icon: ObraIcons.task_list,
                    title: 'Kelola Varian',
                    subtitle: 'Atur varian pada setiap produk',
                    onTap: onKelolaVarian,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.successTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 13,
                    height: 1.3,
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
