import 'package:dtw_app/features/akun/data/models/busboy_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

// TODO(open-question): the profile data source is unresolved (Open Question 1).
// This provider returns hard-coded, in-memory mock data harvested from the
// `profile-saya` Figma reference. When the real source (auth/profile service)
// lands, replace this synchronous provider with an async repository fetch
// (`Future<BusboyProfile>` backed by dio, per knowledge/riverpod-patterns.md)
// and have the screen consume the resulting AsyncValue. Edit + Simpan are
// UI-only stubs (Open Question 2) until the mutation endpoint is specified.

/// Mock backing data for the `profile-saya` screen.
@riverpod
BusboyProfile busboyProfile(Ref ref) {
  return const BusboyProfile(
    busboyId: 'BBY-0123',
    namaLengkap: 'Budi Susanto',
    noTelepon: '0814253526323',
    email: 'budisantoso@dtw.co.id',
    outlet: 'DTW Foodcourt',
    shift: 'Pagi (07:00-15:00)',
  );
}
