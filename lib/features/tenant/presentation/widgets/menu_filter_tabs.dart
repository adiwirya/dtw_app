import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:flutter/material.dart';

/// Horizontally-scrolling pill filter row on the Menu Saya list
/// (`menu-saya` Frame 2011): the selected pill uses a success-tint fill with
/// green text, unselected pills a neutral-tint fill with muted text.
class MenuFilterTabs extends StatelessWidget {
  const MenuFilterTabs({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  /// The pills to render, left to right.
  final List<MenuFilter> filters;

  /// Index of the active pill.
  final int selectedIndex;

  /// Called with the tapped pill's index.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _Pill(
          label: filters[i].display,
          selected: i == selectedIndex,
          onTap: () => onChanged(i),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.successTint : AppColors.neutralTint,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    selected ? AppColors.successGreen : AppColors.neutral500,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
