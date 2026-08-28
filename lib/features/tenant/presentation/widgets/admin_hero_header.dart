import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The green gradient hero band at the top of the Admin status screen
/// (`admin-offline` / `admin-online`).
///
/// Over the `assets/images/admin-hero.png` raster it lays a white status bar,
/// round brand logo, the tenant name + booth, and a rating chip. The white
/// body panel drawn by the screen overlaps the bottom of this band.
class AdminHeroHeader extends StatelessWidget {
  const AdminHeroHeader({required this.info, super.key});

  final TenantAdminInfo info;

  static const double _height = 234;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/admin-hero.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The OS draws the real status bar here; the header runs behind
            // it. A fake `9:41` bar used to sit in this slot, doubling up with
            // the real one on device.
            SizedBox(height: MediaQuery.paddingOf(context).top),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _brandRow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brandLogo(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (info.booth case final booth?) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      ObraIcons.location,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booth,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
              if (info.heroRating case final rating?) ...[
                const SizedBox(height: 12),
                _ratingChip(rating),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The round brand logo chip (`GET /v1/brands/{brandId}`'s `logo_url`), or
  /// a plain storefront icon placeholder when the brand has no logo uploaded
  /// yet, or the image fails to load.
  Widget _brandLogo() {
    final url = info.logoUrl;
    if (url == null) return const _BrandLogoPlaceholder();
    return ClipOval(
      child: Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const _BrandLogoPlaceholder(),
      ),
    );
  }

  Widget _ratingChip(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO(open-question): obra_icons has no plain star glyph; the amber
          // Material star matches the reference fill until an SVG is exported.
          const Icon(Icons.star, size: 16, color: AppColors.starAmber),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

}


/// Round storefront-icon fallback for [AdminHeroHeader]'s brand logo chip —
/// shown when the brand has no `logo_url` yet, or the image fails to load.
class _BrandLogoPlaceholder extends StatelessWidget {
  const _BrandLogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.storefront,
        size: 36,
        color: AppColors.neutral500,
      ),
    );
  }
}
