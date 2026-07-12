import 'package:flutter/foundation.dart';

/// Static, mock tenant identity + operational data shown on the Admin status
/// screen (`admin-offline` / `admin-online`).
///
/// The online/offline flag is NOT part of this model — it is mutable screen
/// state owned by `AdminOnlineStatus` — so this holds only the fields that are
/// constant across both states (brand, hours, `Informasi Tenant` rows).
@immutable
class TenantAdminInfo {
  const TenantAdminInfo({
    required this.name,
    required this.booth,
    required this.brandLogoAsset,
    required this.heroRating,
    required this.joinedLabel,
    required this.rating,
    required this.contact,
    required this.operationalHours,
    required this.operationalDays,
  });

  /// Tenant display name (hero title) — e.g. `KFC Fried Chicken`.
  final String name;

  /// Booth / location label under the name — e.g. `Booth B1`.
  final String booth;

  /// Asset key for the round brand logo chip.
  final String brandLogoAsset;

  /// Rating shown in the hero chip next to the star — e.g. `4.8`.
  final String heroRating;

  /// `Bergabung Sejak` value — e.g. `24 April 2024`.
  final String joinedLabel;

  /// `Rating` value in the Informasi Tenant card — e.g. `4.3`.
  final String rating;

  /// `Contact Tenant` value — e.g. `+6282394627322`.
  final String contact;

  /// `Jam Operasional` hours span — e.g. `10:00 - 22:00 WIB`.
  final String operationalHours;

  /// `Jam Operasional` day cadence — e.g. `Setiap Hari`.
  final String operationalDays;
}
