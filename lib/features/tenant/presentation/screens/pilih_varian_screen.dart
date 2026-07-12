import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_filter_tabs.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The "Pilih Varian" picker (`tambah-varian`): attach existing variants to a
/// menu.
///
/// A search field, Semua / Tunggal / Ganda filter pills, an info hint, and a
/// checkbox list of [VariantSelectRow]s over [savedVariants]. The bottom bar
/// shows the running selection count and a "Tambah" button that advances to
/// `varian-ditambahkan` (the menu form with the picked variants attached).
///
// TODO(open-question): the variant catalogue + filtering are unresolved Open
// Questions; the list is mock data ([savedVariants]) and the filter pills are
// display-only (no filtering applied).
class PilihVarianScreen extends StatefulWidget {
  const PilihVarianScreen({super.key});

  @override
  State<PilihVarianScreen> createState() => _PilihVarianScreenState();
}

class _PilihVarianScreenState extends State<PilihVarianScreen> {
  int _filter = 0;
  // Seeded with the first two variants ticked to match the reference's
  // "2 Varian Dipilih" footer.
  final Set<int> _selected = {0, 1};

  static const List<MenuFilter> _filters = [
    MenuFilter(label: 'Semua', count: 120),
    MenuFilter(label: 'Tunggal', count: 100),
    MenuFilter(label: 'Ganda', count: 22),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(onBack: () => context.canPop() ? context.pop() : null),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: AppInput(
                      leadingIcon: ObraIcons.search,
                      hintText: 'Cari varian...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  MenuFilterTabs(
                    filters: _filters,
                    selectedIndex: _filter,
                    onChanged: (i) => setState(() => _filter = i),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _InfoHint(),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < savedVariants.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VariantSelectRow(
                        data: savedVariants[i].asSelectData,
                        selected: _selected.contains(i),
                        onSelectedChanged: (v) => setState(() {
                          if (v) {
                            _selected.add(i);
                          } else {
                            _selected.remove(i);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            _BottomBar(
              count: _selected.length,
              onTambah: () => context.goNamed(TenantRoutes.varianDitambahkan),
            ),
          ],
        ),
      ),
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
              child: PrimaryButton(label: 'Tambah', onPressed: onTambah),
            ),
          ],
        ),
      ),
    );
  }
}
