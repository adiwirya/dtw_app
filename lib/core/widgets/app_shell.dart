import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent app scaffold that hosts the four main tabs via a
/// [StatefulNavigationShell]. Each tab keeps its own navigation stack, so
/// pushing a detail screen inside a tab preserves the bottom nav.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_NavTab>[
    _NavTab(icon: Icons.room_service_outlined, label: 'Order'),
    _NavTab(icon: Icons.pie_chart_outline, label: 'Performa'),
    _NavTab(icon: Icons.history, label: 'Riwayat'),
    _NavTab(icon: Icons.person_outline, label: 'Akun'),
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
