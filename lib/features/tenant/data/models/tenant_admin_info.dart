import 'package:flutter/foundation.dart';

/// Tenant identity + operational data shown on the Admin status screen
/// (`admin-offline` / `admin-online`).
///
/// [name] and [joinedLabel] come from the real `GET /v1/tenant-branches/{id}`
/// response (see `TenantBranch.toTenantAdminInfo`). The rest of the design's
/// fields (booth/location, brand logo, rating, contact, operating hours) have
/// no backing API field yet — they stay null, and the Admin screen hides
/// those rows/chips rather than show fabricated data.
@immutable
class TenantAdminInfo {
  const TenantAdminInfo({
    required this.name,
    required this.joinedLabel,
    this.booth,
    this.logoUrl,
    this.heroRating,
    this.rating,
    this.contact,
    this.operationalHours,
    this.operationalDays,
  });

  /// Tenant display name (hero title) — e.g. `Janji Jiwa`.
  final String name;

  /// `Bergabung Sejak` value — e.g. `7 Agustus 2026`.
  final String joinedLabel;

  /// Booth / location label under the name — e.g. `Booth B1`. No API source
  /// yet; the hero hides this row when null.
  final String? booth;

  /// The tenant's photo URL for the round brand logo chip — from the branch's
  /// `banner_url`, when the backend has one uploaded. The hero falls back to
  /// a placeholder icon when null.
  final String? logoUrl;

  /// Rating shown in the hero chip next to the star — e.g. `4.8`. No API
  /// source yet; the hero hides the chip when null.
  final String? heroRating;

  /// `Rating` value in the Informasi Tenant card — e.g. `4.3`. No API source
  /// yet; the card hides this row when null.
  final String? rating;

  /// `Contact Tenant` value — e.g. `+6282394627322`. No API source yet; the
  /// card hides this row when null.
  final String? contact;

  /// `Jam Operasional` hours span — e.g. `10:00 - 22:00 WIB`. No API source
  /// yet; the screen hides the whole card when this (or [operationalDays])
  /// is null.
  final String? operationalHours;

  /// `Jam Operasional` day cadence — e.g. `Setiap Hari`.
  final String? operationalDays;
}
