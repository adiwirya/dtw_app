import 'package:flutter/widgets.dart';

/// One coloured summary stat in the profile card's stats box (`Frame 2611`).
///
/// Rendered as a large [value] (optionally followed by a smaller [unit]) over a
/// grey [label], with the value tinted by [color].
@immutable
class AccountStat {
  const AccountStat({
    required this.value,
    required this.label,
    required this.color,
    this.unit,
    this.showStar = false,
  });

  /// Headline number, e.g. `542`, `6`, `4.9`.
  final String value;

  /// Optional smaller suffix rendered after [value], e.g. `Menit`.
  final String? unit;

  /// Supporting caption under the value, e.g. `Tugas Selesai`.
  final String label;

  /// ARGB colour for [value]/[unit]; resolved against `AppColors` at the seam.
  final int color;

  /// Whether an amber rating star trails the value (the rating stat).
  final bool showStar;
}

/// One tappable row in the Akun account menu (`Frame 2612` + chevron).
@immutable
class AccountMenuItem {
  const AccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.routeName,
    this.destructive = false,
  });

  /// Leading glyph shown inside the round chip.
  final IconData icon;

  /// Bold row title, e.g. `Profil Saya`.
  final String title;

  /// Grey supporting line, e.g. `Lihat dan edit profil`.
  final String subtitle;

  /// Named route to navigate to on tap. When null the tap is an unresolved
  /// action stub (see the screen's `// TODO(open-question)`).
  final String? routeName;

  /// Destructive styling (red icon + label) — the `Keluar` row.
  final bool destructive;
}

/// Model backing the `akun` frame: the busboy's identity, the three-up
/// performance stats, the account menu, and the logout row.
@immutable
class AkunAccount {
  const AkunAccount({
    required this.name,
    required this.busboyId,
    required this.joinedLabel,
    required this.stats,
    required this.menuItems,
    required this.logoutItem,
  });

  /// The session login handle (`sessionUsernameProvider`), not a display
  /// name: the API has no display-name field. Rendered as `Hi, <name>`;
  /// null (unknown) drops the name from the greeting instead of substituting
  /// a fabricated one — mirrors `OrderHomeHeader`.
  final String? name;

  /// Busboy identifier — `-` (the API has no busboy-profile endpoint yet).
  final String busboyId;

  /// Join date caption — `-` (the API has no busboy-profile endpoint yet).
  final String joinedLabel;

  /// The three profile stats shown in the bordered stats box.
  final List<AccountStat> stats;

  /// The navigable/actionable menu rows (Profil Saya, Ubah Kata Sandi, …).
  final List<AccountMenuItem> menuItems;

  /// The destructive logout row, separated by a hairline from [menuItems].
  final AccountMenuItem logoutItem;
}
