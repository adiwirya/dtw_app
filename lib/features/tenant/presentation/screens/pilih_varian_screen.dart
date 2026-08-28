import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_filter_tabs.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The type filter offered above the picker list. Derived from the variant's
/// own [VariantType], so unlike the old mock pills these counts and this
/// filtering are real.
enum _VarianFilter { semua, tunggal, ganda }

/// The "Pilih Varian" picker (`tambah-varian`): attach existing variants to a
/// menu.
///
/// Backed by the real [variantListProvider] (`GET /v1/modifier-groups`) — the
/// same source `KelolaVarianScreen` uses. A search field filters by name and
/// the Semua / Tunggal / Ganda pills filter by type, both client-side over the
/// already-fetched list (the endpoint has no query params for either). The
/// bottom bar shows the running selection count and "Tambah" advances to
/// `varian-ditambahkan`.
///
// TODO(open-question): the picked variants are not yet attached to a menu —
// `POST /v1/products/{id}/modifier-groups/sync` exists but the menu form it
// would attach to is still a mock save (see `menu_provider.dart`). "Tambah"
// therefore only advances the prototype flow.
class PilihVarianScreen extends ConsumerStatefulWidget {
  const PilihVarianScreen({super.key});

  @override
  ConsumerState<PilihVarianScreen> createState() => _PilihVarianScreenState();
}

class _PilihVarianScreenState extends ConsumerState<PilihVarianScreen> {
  _VarianFilter _filter = _VarianFilter.semua;

  /// Selected variants, by [VariantData.id].
  ///
  /// Keyed by id rather than list index: the list is fetched and then
  /// filtered/searched, so an index no longer identifies a stable variant.
  final Set<String> _selectedIds = {};

  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesType(VariantData variant) => switch (_filter) {
    _VarianFilter.semua => true,
    _VarianFilter.tunggal => variant.type == VariantType.tunggal,
    _VarianFilter.ganda => variant.type == VariantType.ganda,
  };

  List<VariantData> _visible(List<VariantData> all) {
    final query = _search.text.trim().toLowerCase();
    return [
      for (final variant in all)
        if (_matchesType(variant) &&
            (query.isEmpty || variant.name.toLowerCase().contains(query)))
          variant,
    ];
  }

  List<MenuFilter> _filterTabs(List<VariantData> all) => [
    MenuFilter(label: 'Semua', count: all.length),
    MenuFilter(
      label: 'Tunggal',
      count: all.where((v) => v.type == VariantType.tunggal).length,
    ),
    MenuFilter(
      label: 'Ganda',
      count: all.where((v) => v.type == VariantType.ganda).length,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final variantsAsync = ref.watch(variantListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(onBack: () => context.canPop() ? context.pop() : null),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AppInput(
                controller: _search,
                leadingIcon: ObraIcons.search,
                hintText: 'Cari varian...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: variantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(errorMessage(error))),
                data: _buildList,
              ),
            ),
            _BottomBar(
              count: _selectedIds.length,
              onTambah: () => context.goNamed(TenantRoutes.varianDitambahkan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<VariantData> all) {
    final visible = _visible(all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenuFilterTabs(
          filters: _filterTabs(all),
          selectedIndex: _filter.index,
          onChanged: (i) =>
              setState(() => _filter = _VarianFilter.values[i]),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _InfoHint(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: visible.isEmpty
              ? _EmptyResult(hasVariants: all.isNotEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final variant = visible[i];
                    return VariantSelectRow(
                      data: variant.asSelectData,
                      selected: _selectedIds.contains(variant.id),
                      onSelectedChanged: (selected) => setState(() {
                        if (selected) {
                          _selectedIds.add(variant.id);
                        } else {
                          _selectedIds.remove(variant.id);
                        }
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// The "< Pilih Varian" top bar.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            InkResponse(
              onTap: onBack,
              radius: 20,
              child: const Icon(
                ObraIcons.arrow_left,
                size: 24,
                color: AppColors.neutral900,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Pilih Varian',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

/// The info row: an information glyph + the "Pilih varian..." hint text.
class _InfoHint extends StatelessWidget {
  const _InfoHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 20, color: AppColors.neutral500),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pilih varian yang ingin ditambahkan ke menu ini.',
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown when the search/type filter matches nothing, or the brand has no
/// variants at all yet — two different situations, so two different messages.
class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.hasVariants});

  final bool hasVariants;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          hasVariants
              ? 'Varian tidak ditemukan.'
              : 'Belum ada varian untuk dipilih.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.neutral500,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// The sticky bottom bar: "N Varian Dipilih" + a "Tambah" button.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.count, required this.onTambah});

  final int count;
  final VoidCallback onTambah;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, -2),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count Varian Dipilih',
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 170,
              child: PrimaryButton(
                label: 'Tambah',
                // Nothing to attach until at least one variant is ticked.
                onPressed: count == 0 ? null : onTambah,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
