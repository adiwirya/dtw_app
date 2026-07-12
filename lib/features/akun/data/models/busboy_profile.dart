import 'package:flutter/foundation.dart';

/// Editable profile detail backing the `profile-saya` frame.
///
/// Distinct from `AkunAccount` (the account-home summary): this carries the
/// full editable field set shown on Profil Saya. [busboyId] overlaps with the
/// account summary but every other field (contact + employment info) is unique
/// to this screen.
@immutable
class BusboyProfile {
  const BusboyProfile({
    required this.busboyId,
    required this.namaLengkap,
    required this.noTelepon,
    required this.email,
    required this.outlet,
    required this.shift,
  });

  /// Read-only busboy identifier, e.g. `BBY-0123`.
  final String busboyId;

  /// Full name, e.g. `Budi Susanto`.
  final String namaLengkap;

  /// Phone number, e.g. `0814253526323`.
  final String noTelepon;

  /// Optional email, e.g. `budisantoso@dtw.co.id`.
  final String email;

  /// Assigned outlet / location, e.g. `DTW Foodcourt`.
  final String outlet;

  /// Shift label, e.g. `Pagi (07:00-15:00)`.
  final String shift;
}
