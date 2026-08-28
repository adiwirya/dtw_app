import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/features/akun/data/models/akun_account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'akun_provider.g.dart';

// TODO(open-question): the account data source is unresolved (Open Question 1).
// This provider returns hard-coded, in-memory mock data harvested from the
// `akun` Figma reference. When the real source (auth/profile service) lands,
// replace this synchronous provider with an async repository fetch
// (`Future<AkunAccount>` backed by dio, per knowledge/riverpod-patterns.md) and
// have the screen consume the resulting AsyncValue.

/// Mock backing data for the `akun` account screen.
@riverpod
AkunAccount akunAccount(Ref ref) {
  return const AkunAccount(
    name: 'Adi Wiryadi',
    busboyId: 'BBY-0123',
    joinedLabel: '12 Januari 2024',
    stats: [
      AccountStat(
        value: '542',
        label: 'Tugas Selesai',
        color: 0xFF10A760, // AppColors.successGreen
      ),
      AccountStat(
        value: '6',
        unit: 'Menit',
        label: 'Rata-rata waktu antar',
        color: 0xFF3B82F6, // AppColors.statBlue
      ),
      AccountStat(
        value: '4.9',
        label: 'Rating Pelanggan',
        color: 0xFFF5B301, // AppColors.starAmber
        showStar: true,
      ),
    ],
    menuItems: [
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
    logoutItem: AccountMenuItem(
      icon: ObraIcons.log_out,
      title: 'Keluar',
      subtitle: 'Keluar dari akun',
      destructive: true,
    ),
  );
}
