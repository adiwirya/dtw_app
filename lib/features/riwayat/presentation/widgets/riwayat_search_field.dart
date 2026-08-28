import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The `Cari riwayat...` search field at the top of the white panel
/// (`riwayat-*` `Input`, 358x44): a white 44px-tall rounded field with a
/// neutral hairline border, a leading search glyph and placeholder text.
///
/// Filters the history list by tenant name or table client-side — the busboy
/// deliveries endpoint takes no search query param, and the list is already
/// fetched in full.
class RiwayatSearchField extends StatelessWidget {
  const RiwayatSearchField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  /// Controls the query text. Owned by the caller.
  final TextEditingController controller;

  /// Called on every edit so the caller can re-filter.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral100),
      ),
      child: Row(
        children: [
          const Icon(ObraIcons.search, size: 20, color: AppColors.neutral300),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 14,
                height: 1.2,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Cari riwayat...',
                hintStyle: TextStyle(
                  color: AppColors.neutral300,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
