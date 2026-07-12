import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// Persistent tenant scaffold hosting the four tenant tabs via a
/// [StatefulNavigationShell]. Mirrors the busboy `AppShell` pattern (each tab
/// keeps its own navigation stack) but with the tenant tab set, icons and the
/// raised "Order" FAB from the `menu-order-baru` reference `Navbar`.
///
/// Tabs → home routes (see the tenant manifest `bottomNav`):
///   Order → menu-order-baru, Menu → menu-saya,
///   Laporan → laporan, Akun → admin-offline.
/// The nav labels/icons follow the design `Navbar`: a raised green circular
/// "Order" FAB (`Icon / receipt-text`) flanked by flat Menu (`layout-list`),
/// Laporan (`chart-no-axes-combined`) and Akun (`user-03`) items. Branch
/// targets are unchanged from item 01 — only the labels/icons/FAB changed.
class TenantShell extends StatelessWidget {
  const TenantShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_NavTab>[
    _NavTab(icon: ObraIcons.receipt, label: 'Order'), // receipt-text (FAB)
    _NavTab(icon: ObraIcons.task_list, label: 'Menu'), // layout-list
    _NavTab(icon: ObraIcons.bar_chart, label: 'Laporan'), // chart-no-axes
    _NavTab(icon: ObraIcons.user, label: 'Akun'), // user-03
  ];

  void _onTap(int index) {
    // Re-tapping the active tab pops it back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNavBar(
        tabs: _tabs,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The tenant bottom nav: a white bar with a raised green circular "Order" FAB
/// over the first slot and three flat items to its right.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 64;
  static const double _fabSize = 50;
  // How far the FAB centre sits above the bar's top edge.
  static const double _fabRaise = 22;

  @override
  Widget build(BuildContext context) {
    final slotWidth = MediaQuery.sizeOf(context).width / tabs.length;

    return SizedBox(
      height: _barHeight + _fabRaise + MediaQuery.viewPaddingOf(context).bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The white bar with flat items (slot 0 shows only the "Order"
          // label; its icon is the raised FAB drawn on top).
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: AppColors.white,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: _barHeight,
                  child: Row(
                    children: [
                      _OrderLabelSlot(
                        label: tabs.first.label,
                        selected: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      for (var i = 1; i < tabs.length; i++)
                        Expanded(
                          child: _FlatNavItem(
                            tab: tabs[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // The raised green FAB over slot 0.
          Positioned(
            left: 0,
            width: slotWidth,
            // Circle centred just above the bar's top edge.
            bottom: MediaQuery.viewPaddingOf(context).bottom +
                _barHeight -
                _fabSize / 2,
            child: Center(
              child: _OrderFab(
                icon: tabs.first.icon,
                onTap: () => onTap(0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slot 0 in the bar: just the "Order" label (the icon is the raised FAB).
class _OrderLabelSlot extends StatelessWidget {
  const _OrderLabelSlot({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: TextStyle(
                  color:
                      selected ? AppColors.successGreen : AppColors.neutral500,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The raised green circular "Order" FAB.
class _OrderFab extends StatelessWidget {
  const _OrderFab({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.successGreen,
      shape: const CircleBorder(),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _BottomNavBar._fabSize,
          height: _BottomNavBar._fabSize,
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
      ),
    );
  }
}

class _FlatNavItem extends StatelessWidget {
  const _FlatNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.successGreen : AppColors.neutral500;
    return InkWell(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        label: tab.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
