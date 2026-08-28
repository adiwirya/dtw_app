import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The variant management screen (`kelola-varian` empty / `varian-disimpan`
/// saved).
///
/// Hosted inside the tenant shell (Menu Saya tab). Reached from the menu form's
/// "Tambah Varian" action (`tambah-menu` → `kelola-varian`). Shows a "Belum
/// ada Varian Menu" placeholder when the tenant has no saved variants, or the
/// list with a "Digunakan di N menu" footer once it does — driven by the real
/// `GET /v1/modifier-groups` list rather than a route-selected mock state.
///
/// The search field filters by variant name client-side over the fetched list
/// — the endpoint takes no query param for it.
class KelolaVarianScreen extends ConsumerStatefulWidget {
  const KelolaVarianScreen({super.key});

  @override
  ConsumerState<KelolaVarianScreen> createState() =>
      _KelolaVarianScreenState();
}

class _KelolaVarianScreenState extends ConsumerState<KelolaVarianScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VariantData> _visible(List<VariantData> all) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return all;
    return [
      for (final variant in all)
        if (variant.name.toLowerCase().contains(query)) variant,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final variantsAsync = ref.watch(variantListProvider);
    // Only known once the fetch resolves — the bottom "Buat Varian" button is
    // the empty state's action, so it stays hidden while loading/erroring.
    // Keyed off the unfiltered list: a search that matches nothing must not
    // turn this into the "no variants yet" screen.
    final isEmpty = variantsAsync.valueOrNull?.isEmpty ?? false;

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
                  _Header(
                    // Header "+ Tambah Varian" opens the "Pilih Varian" picker
                    // to attach existing variants to the menu.
                    onTambahVarian: () =>
                        context.goNamed(TenantRoutes.tambahVarian),
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _search,
                    leadingIcon: ObraIcons.search,
                    hintText: 'Cari varian...',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: variantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(errorMessage(error))),
                data: (all) {
                  if (all.isEmpty) return const _EmptyState();
                  final variants = _visible(all);
                  if (variants.isEmpty) return const _NoSearchResult();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: variants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, i) => _VariantManageCard(
                      data: variants[i],
                      onTap: () => context.goNamed(
                        TenantRoutes.varianDiisi,
                        pathParameters: {'variantId': variants[i].id},
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: PrimaryButton(
                  label: 'Buat Varian',
                  // Prototype: kelola-varian --(Buat Varian)--> tambah-varian-2
                  onPressed: () => context.goNamed(TenantRoutes.tambahVarian2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The "Varian Saya" header with a single subtitle and a green
/// "+ Tambah Varian" action (`kelola-varian` Frame 2133).
class _Header extends StatelessWidget {
  const _Header({required this.onTambahVarian});

  final VoidCallback onTambahVarian;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Varian Saya',
                style: TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Atur varian pada setiap produk',
                style: TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onTambahVarian,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ObraIcons.add, size: 20, color: AppColors.successGreen),
                SizedBox(width: 8),
                Text(
                  'Tambah Varian',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The centered "Belum ada Varian Menu" placeholder (`kelola-varian`).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO(open-question): the "file-add" illustration raster isn't in
            // the asset cache; this glyph stack approximates it.
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.article_outlined,
                      size: 88,
                      color: AppColors.neutral300,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada Varian Menu',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan varian (size, level pedas, dll) dengan tambahan harga '
              'jika ada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neutral500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the tenant HAS variants but the search matches none — distinct
/// from [_EmptyState], which means "no variants created yet".
class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Varian tidak ditemukan.',
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

/// A saved-variant card on `varian-disimpan`: name + type chip, `N Opsi`, the
/// option preview, and a "Digunakan di N menu" footer with a chevron.
class _VariantManageCard extends StatelessWidget {
  const _VariantManageCard({required this.data, required this.onTap});

  final VariantData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            style: const TextStyle(
                              color: AppColors.neutral900,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(type: data.type),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.optionCount} Opsi',
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    // The option-name preview needs the full option list,
                    // which the modifier-groups list endpoint doesn't return
                    // (only the count) — shown only once actually known.
                    if (data.options != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.optionNames.join(', '),
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // "Digunakan di N menu" has no API source at all yet — the
              // whole footer (divider included) is hidden rather than shown
              // with a fabricated count.
              if (data.usedInMenuCount case final usedInMenuCount?) ...[
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.hairline,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: AppColors.successGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Digunakan di $usedInMenuCount menu',
                          style: const TextStyle(
                            color: AppColors.neutral500,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const Icon(
                        ObraIcons.chevron_right,
                        size: 20,
                        color: AppColors.neutral300,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The Tunggal / Ganda pill (mirrors the reused [VariantSelectRow] chip).
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final VariantType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        type == VariantType.tunggal ? 'Tunggal' : 'Ganda',
        style: const TextStyle(
          color: AppColors.success700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
