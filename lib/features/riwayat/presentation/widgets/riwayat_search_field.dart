import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The `Cari riwayat...` search field at the top of the white panel
/// (`riwayat-*` `Input`, 358x44): a white 44px-tall rounded field with a
/// neutral hairline border, a leading search glyph and placeholder text.
///
/// UI-only for now — search filtering is out of scope for this work item
/// (Open Question), so the field is a non-editable affordance.
// TODO(open-question): wire real search once the history data source lands.
class RiwayatSearchField extends StatelessWidget {
  const RiwayatSearchField({super.key});

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
      child: const Row(
        children: [
          Icon(ObraIcons.search, size: 20, color: AppColors.neutral300),
          SizedBox(width: 10),
          Text(
            'Cari riwayat...',
            // TODO(open-question): Open Sans in the cache; not bundled yet.
            style: TextStyle(
              color: AppColors.neutral300,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
