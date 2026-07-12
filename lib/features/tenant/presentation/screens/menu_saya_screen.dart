import 'dart:async';

import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/kelola_menu_sheet.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_filter_tabs.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_saya_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The Menu Saya tab home (`menu-saya` / `menu-saya-2`) and the post-add list
/// (`menu-berhasil-ditambahkan`).
///
/// Hosted inside the tenant shell (bottom nav supplied by `TenantShell`). The
/// header's right action opens the `kelola-menu` modal by default; on the
/// `menu-berhasil-ditambahkan` entry ([recentlyAdded] true) it becomes
/// "+ Tambah Menu" and the just-saved "Paket Komplit" row is previewed at the
/// bottom of the list (there is no persisted backend yet — Open Questions 3/5/6).
class MenuSayaScreen extends ConsumerStatefulWidget {
  const MenuSayaScreen({this.recentlyAdded = false, super.key});

  /// Renders the `menu-berhasil-ditambahkan` variant: swaps the header action
  /// to "+ Tambah Menu" and appends the recently-added preview row.
  final bool recentlyAdded;

  @override
  ConsumerState<MenuSayaScreen> createState() => _MenuSayaScreenState();
}

class _MenuSayaScreenState extends ConsumerState<MenuSayaScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final menus = ref.watch(menuListProvider);
    final rows = [
      ...menus,
      if (widget.recentlyAdded) recentlyAddedMenu,
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MenuSayaHeader(
                    actionLabel:
                        widget.recentlyAdded ? 'Tambah Menu' : 'Kelola Menu',
                    actionIcon: widget.recentlyAdded
                        ? ObraIcons.add
                        : ObraIcons.sliders,
                    onAction: _onHeaderAction,
                  ),
                  const SizedBox(height: 16),
                  const AppInput(
                    leadingIcon: ObraIcons.search,
                    hintText: 'Cari menu...',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            MenuFilterTabs(
              filters: menuFilters,
              selectedIndex: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, i) => MenuItemCard(
                  data: rows[i],
                  onActiveChanged: i < menus.length
                      ? (active) => ref
                          .read(menuListProvider.notifier)
                          .setActive(i, active: active)
                      : null,
                  onTap: () => context.goNamed(TenantRoutes.menuDiisi),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onHeaderAction() {
    if (widget.recentlyAdded) {
      context.goNamed(TenantRoutes.tambahMenu);
      return;
    }
    unawaited(
      showKelolaMenuSheet(
        context,
        onTambahMenu: () => context.goNamed(TenantRoutes.tambahMenu),
        onKelolaVarian: () => context.goNamed(TenantRoutes.kelolaVarian),
      ),
    );
  }
}
