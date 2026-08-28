import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
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
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Client-side name search over the fetched list — `GET /v1/products` takes
  /// no search query param.
  List<MenuItemData> _visible(List<MenuItemData> all) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return all;
    return [
      for (final menu in all)
        if (menu.name.toLowerCase().contains(query)) menu,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menusAsync = ref.watch(menuListProvider);
    final branch = ref.watch(currentTenantBranchProvider).valueOrNull;

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
                    subtitleName: branch?.branchName ?? '',
                    subtitleBooth: branch?.areaName ?? '',
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _search,
                    leadingIcon: ObraIcons.search,
                    hintText: 'Cari menu...',
                    onChanged: (_) => setState(() {}),
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
              child: menusAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(errorMessage(error))),
                data: _buildList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<MenuItemData> all) {
    // The `menu-berhasil-ditambahkan` frame previews the just-saved row. It is
    // frame state rather than fetched data, so it is searchable but never
    // toggleable (see the provider-index lookup below).
    final candidates = [
      ...all,
      if (widget.recentlyAdded) recentlyAddedMenu,
    ];
    final rows = _visible(candidates);

    // Only reachable via the search field, so this screen owns the state. An
    // empty *fetched* list keeps its previous blank-list rendering.
    if (rows.isEmpty && _search.text.trim().isNotEmpty) {
      return const _NoSearchResult();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final menu = rows[i];
        // `MenuList.setActive` addresses the PROVIDER's list by position, so
        // the index has to be resolved against the unfiltered list. Passing
        // the filtered row index would flip availability on a different
        // product than the one whose toggle was tapped.
        final providerIndex = all.indexWhere((m) => m.id == menu.id);
        return MenuItemCard(
          data: menu,
          onActiveChanged: providerIndex == -1
              ? null
              : (active) => ref
                    .read(menuListProvider.notifier)
                    .setActive(providerIndex, active: active),
          onTap: () => context.goNamed(TenantRoutes.menuDiisi),
        );
      },
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

/// Shown when the menu search matches nothing. Distinct from an empty fetched
/// list, which keeps its original blank-list rendering.
class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Menu tidak ditemukan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.neutral500,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
