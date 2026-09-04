import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/features/akun/data/models/busboy_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

// TODO(open-question): the profile data source is unresolved (Open Question 1).
// `namaLengkap` is the real session username; every other field below is `-`
// because the busboy API has no profile endpoint yet. When one lands, replace
// this synchronous provider with an async repository fetch
// (`Future<BusboyProfile>` backed by dio, per knowledge/riverpod-patterns.md)
// and have the screen consume the resulting AsyncValue. Edit + Simpan are
// UI-only stubs (Open Question 2) until the mutation endpoint is specified.

/// Backing data for the `profile-saya` screen.
@riverpod
BusboyProfile busboyProfile(Ref ref) {
  final username = ref.watch(sessionUsernameProvider);
  return BusboyProfile(
    busboyId: '-',
    namaLengkap: username ?? '-',
    noTelepon: '-',
    email: '-',
    outlet: '-',
    shift: '-',
  );
}
