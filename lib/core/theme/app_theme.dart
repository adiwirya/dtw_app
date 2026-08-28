import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Foundation/Success/600 — active bottom-nav tab / success accent.
  static const Color successGreen = Color(0xFF10A760);

  /// Foundation/Neutral/500 — inactive bottom-nav tab / secondary text.
  static const Color neutral500 = Color(0xFF667085);

  /// Neutral/100 — input borders / dividers.
  static const Color neutral100 = Color(0xFFD0D3D9);

  /// Foundation/Neutral/300 — muted chevrons / tertiary iconography.
  static const Color neutral300 = Color(0xFF989FAD);

  /// Foundation/Neutral/900 — primary text.
  static const Color neutral900 = Color(0xFF2B2F38);

  /// Neutral/True White — surfaces / bottom-nav background.
  static const Color white = Color(0xFFFFFFFF);

  /// Foundation/Success/50 — success tint (e.g. the "Ke Meja" icon tile).
  static const Color successTint = Color(0xFFE7F8F0);

  /// Foundation/Success/700 — pressed / darker success accent.
  static const Color success700 = Color(0xFF0D824B);

  /// Top of the login hero gradient (`login-default` Rectangle 367).
  static const Color heroGradientTop = Color(0xFFDCF9EB);

  /// Fill of a selected role card (`login-tenantt` Busboy card).
  static const Color cardSelectedFill = Color(0xFFF5FDF9);

  /// Border of a selected role card (`login-tenantt` Busboy card).
  static const Color cardSelectedBorder = Color(0xFFB6E9D1);

  // --- Performa dashboard (performa-v1 / performa-v2) ---

  // TODO(open-question): the header on both Performa frames is a photographic
  // green gradient raster ("ChatGPT Image ..." 390x341) that was not exported
  // to the asset cache. These two stops approximate it; swap for the real
  // asset once available.
  /// Top of the Performa header gradient.
  static const Color headerGreenTop = Color(0xFF0C6B3C);

  /// Bottom of the Performa header gradient.
  static const Color headerGreenBottom = Color(0xFF12A45C);

  /// Card drop-shadow colour (token `Card Shadow` — #063336 @ 10%).
  static const Color cardShadow = Color(0x1A063336);

  /// Periwinkle bars of the `performa-v1` "Performa per Jam" chart.
  static const Color chartBarPeriwinkle = Color(0xFF8E9BF3);

  /// Idle light-blue bars of the `performa-v2` "Aktivitas Mingguan" chart.
  static const Color chartBarBlueIdle = Color(0xFFBFD4FF);

  /// Highlighted ("Hari Ini") bar of the `performa-v2` weekly chart.
  static const Color chartBarBlueActive = Color(0xFF3B6FE3);

  /// "Tercepat" delivery-time accent (`performa-v1` Waktu Antar).
  static const Color accentBlue = Color(0xFF3B82F6);

  /// "Terlama" delivery-time accent (`performa-v1` Waktu Antar).
  static const Color accentAmber = Color(0xFFE9A23B);

  /// Rating star fill (`4.9` metric card).
  static const Color starAmber = Color(0xFFF5B301);

  // --- Akun (account) screen (akun frame) ---

  /// Pale-grey fill of the round icon chips on the Akun menu rows
  /// (`Frame 2425`, 40x40) — approximates the exported neutral tint.
  static const Color neutralTint = Color(0xFFF2F4F7);

  /// Hairline border/divider on the Akun profile stats box and between the
  /// menu list and the logout row (`Rectangle 1273`).
  static const Color hairline = Color(0xFFEEF0F3);

  /// Destructive accent — the `Keluar` (logout) icon + label.
  static const Color dangerRed = Color(0xFFE5484D);

  /// Tint behind the destructive `Keluar` icon chip.
  static const Color dangerTint = Color(0xFFFDECEC);

  /// `6 Menit` "Rata-rata waktu antar" stat value on the Akun profile card.
  static const Color statBlue = accentBlue;

  // --- Menu Order (menu-order-* frames) ---

  // TODO(open-question): the "Dari Tenant" (blue) and "Pelanggan" (purple)
  // icon-tile colors are not in tokens.json; these are eyeballed from the
  // references and mirror the private values in [OrderCard]/[SuccessModal].
  // Replace with real tokens if/when they are added.
  /// Background of the "Dari Tenant" icon tile.
  static const Color orderTileTenantBg = Color(0xFFEAF1FB);

  /// Glyph color of the "Dari Tenant" icon tile.
  static const Color orderTileTenantIcon = Color(0xFF3B7DD8);

  /// Background of the "Pelanggan" icon tile.
  static const Color orderTileCustomerBg = Color(0xFFF4ECFB);

  /// Glyph color of the "Pelanggan" icon tile.
  static const Color orderTileCustomerIcon = Color(0xFF9B51E0);

  /// Red count badge on the "Ambil" sub-tab (`menu-order-baru`).
  static const Color orderBadgeRed = Color(0xFFE5484D);

  // --- Order / Riwayat detail (detail-selesai / detail-riwayat frames) ---

  /// Fill of the "Waktu Antar / Diselesaikan" summary box on the detail
  /// identity card (`Frame 2600`) — measured #F0F2F2 from the references.
  static const Color detailInfoBoxBg = Color(0xFFF0F2F2);

  /// Amber count badge on the "Antar" sub-tab (`menu-order-baru`).
  static const Color orderBadgeAmber = Color(0xFFE9A23B);

  // --- Tenant shared widgets (menu / order / varian / admin frames) -------

  // --- Order rejection flow (pesanan-ditolak / konfirmasi-pesanan) ---------

  /// Fill of a rejected per-item availability card (`konfirmasi-pesanan`).
  // TODO(open-question): not a named token in tokens.json; measured light-pink
  // from the reference.
  static const Color rejectedItemFill = Color(0xFFFDF3F2);

  /// Border of a rejected per-item availability card (`konfirmasi-pesanan`).
  // TODO(open-question): not a named token in tokens.json; measured from the
  // reference.
  static const Color rejectedItemBorder = Color(0xFFF7C6C3);

  /// Tinted background of the red "Tidak Tersedia" chip on a rejected item.
  static const Color dangerChipTint = Color(0xFFFDECEC);

  /// Off-state track of the green pill switch used across the tenant screens
  /// (menu-item "Aktif", order per-item availability, varian rule toggles,
  /// admin online/offline). Eyeballed light-grey from the references.
  // TODO(open-question): not a named token in tokens.json; confirm value.
  static const Color toggleTrackOff = Color(0xFFE4E7EC);
}

class AppSpacing {
  const AppSpacing._();
}

class AppTheme {
  const AppTheme._();

  /// Open Sans is the design's body family. Every screen writes bare
  /// `TextStyle(fontSize:, fontWeight:, color:)` with no family, and `Text`
  /// merges those onto the ambient `DefaultTextStyle` — which Material takes
  /// from this `textTheme`. So setting it here is what gives the whole app the
  /// right family without touching ~200 individual styles.
  ///
  /// Bundled under `assets/fonts/` and declared in `pubspec.yaml`, not fetched
  /// at runtime: a network-fetched family never resolves in `flutter_test`, so
  /// the goldens would keep pinning the harness fallback instead of real text.
  static const fontFamily = 'Open Sans';

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: fontFamily,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        fontFamily: fontFamily,
      );
}
