import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/features/akun/data/models/akun_account.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'akun_provider.g.dart';

// TODO(open-question): the account data source is unresolved (Open Question 1).
// `name` is the real session display name; every other identity/stat field
// below is `-` because the busboy API has no profile/performance endpoint yet.
// When one lands, replace this synchronous provider with an async repository
// fetch (`Future<AkunAccount>` backed by dio, per
// knowledge/riverpod-patterns.md) and have the screen consume the resulting
// AsyncValue.

/// The logged-in busboy's average customer rating (`GET
/// /v1/busboys/{user}/rating`), already formatted (e.g. `'4.8'`) — or null
/// when there's no session user id yet, no ratings exist, or the fetch
/// failed. A display nicety, not core profile data, so this never surfaces
/// an error — [akunAccount] just falls back to `-` when this is null.
@riverpod
Future<String?> busboyRating(Ref ref) async {
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) return null;

  try {
    final rating = await ref
        .watch(busboyDeliveryRepositoryProvider)
        .fetchRating(userId: userId);
    return rating.average?.toStringAsFixed(1);
  } on Object {
    return null;
  }
}

/// Backing data for the `akun` account screen.
@riverpod
AkunAccount akunAccount(Ref ref) {
  final name = ref.watch(sessionNameProvider);
  final rating = ref.watch(busboyRatingProvider).valueOrNull;
  return AkunAccount(
    name: name,
    busboyId: '-',
    joinedLabel: '-',
    stats: [
      const AccountStat(
        value: '-',
        label: 'Tugas Selesai',
        color: 0xFF10A760, // AppColors.successGreen
      ),
      const AccountStat(
        value: '-',
        label: 'Rata-rata waktu antar',
        color: 0xFF3B82F6, // AppColors.statBlue
      ),
      AccountStat(
        value: rating ?? '-',
        label: 'Rating Pelanggan',
        color: 0xFFF5B301, // AppColors.starAmber
        showStar: rating != null,
      ),
    ],
    menuItems: const [
      AccountMenuItem(
        icon: ObraIcons.user,
        title: 'Profil Saya',
        subtitle: 'Lihat dan edit profil',
        routeName: AppRoutes.akunProfile,
      ),
      // TODO(open-question): the routes below are unresolved account actions;
      // their taps are stubbed in the screen until the flows are specified.
      AccountMenuItem(
        icon: ObraIcons.lock,
        title: 'Ubah Kata Sandi',
        subtitle: 'Atur ulang kata sandi akun',
      ),
      AccountMenuItem(
        icon: ObraIcons.globe,
        title: 'Bahasa',
        subtitle: 'Atur bahasa sesuai preferensi anda',
      ),
      AccountMenuItem(
        icon: ObraIcons.circle_question,
        title: 'Bantuan & FAQ',
        subtitle: 'Pusat bantuan dan pertanyaan umum',
      ),
      AccountMenuItem(
        icon: ObraIcons.shield_check,
        title: 'Kebijakan Privasi',
        subtitle: 'Ketentuan dan kebijakan aplikasi',
      ),
    ],
    // The tap is wired to the real `AuthController.logout` by `AkunScreen`.
    logoutItem: const AccountMenuItem(
      icon: ObraIcons.log_out,
      title: 'Keluar',
      subtitle: 'Keluar dari akun',
      destructive: true,
    ),
  );
}
