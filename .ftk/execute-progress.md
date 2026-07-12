# Execute Progress — DTW Order (Busboy)

Spec: `ai_specs/0001-busboy-order-app/spec.md`
Branch: `feat/busboy-order-app`
Mode: **no-commit, no-push** (per-item snapshots are `git write-tree` tree hashes, not commits; resume relies on hashes recorded below).
Run base tree: `4f2ffde`

## Run decisions
- Logic gaps (auth, data sources, order-state transitions, empty/error states): build static UI with **mock/in-memory data + stubbed Riverpod providers behind TODOs** referencing the Open Questions. No invented backend.
- Performa (WI 08): build **both v1 and v2**.
- Scope: **all 12 items**.

## Order (topological)
01 → 02 → 03 → 04 → 05 → 06 → 08 → 11 → 07 → 09 → 10 → 12

## Ledger
<!-- one line per completed item: <item>: complete (<baseTree7>..<headTree7>, verdicts — Minors deferred) -->
01 app-shell: complete (0438542..bb61937, spec PASS / quality Approved) — Minors: golden fixture named home_screen.png (rename to login_screen.png); Akun tab test asserts path only not body text.
02 shared-inputs: complete (c71623f..6d28ae2, spec PASS / quality Approved, no findings). APIs: PrimaryButton({label, onPressed?}); AppInput({controller?, leadingIcon?, hintText?, label?, obscureText, trailing?, enabled, ...}) — obscureText auto-adds eye toggle. Added AppColors.neutral100 (#D0D3D9). TODO: Open Sans font not bundled (no google_fonts dep).
03 order-card: complete (f31b058..23f1645, spec PASS / quality Approved) — Minor: AppColors.success700 (#0D824B) added but unused (dead token). API: OrderCard({required OrderCardData data, onTap?, onDetailTap?, onPrimaryAction?, primaryActionLabel?}); enum OrderStatus{baru,antar,selesai}; OrderCardData(orderId,time,tenantName,tableName,location,customerName,itemCount,status,deliveredDate?,deliveredTime?). Added AppColors.successTint(#E7F8F0), success700(#0D824B). Tenant/customer tile tints eyeballed (not in tokens).
04 tab-bar: complete (44be729..b6c0e14, spec PASS / quality Approved, no findings). API: SegmentedTabBar({required List<SegmentedTabItem> items, required int selectedIndex, required ValueChanged<int> onChanged}); SegmentedTabItem({required label, icon?, badge?}). Underline style, height 43, active=successGreen/w600+2px underline, inactive=neutral500. onChanged not fired on active re-tap.
05 success-modal: complete (f2c1f1d..7b9082f, spec PASS / quality Approved, no findings). API: showSuccessModal(context,{required onConfirm, title, message, confirmLabel, details?, barrierDismissible}); SuccessModal({onConfirm,title,message,confirmLabel,details?}); SuccessModalDetail({icon,label,value,tileColor?,iconColor?}). Centered Dialog. Defaults: title 'Tugas Berhasil Diambil!', msg 'Silahkan antar pesanan ke meja tujuan', label 'Mengerti'. Widget pops then calls onConfirm — item 07 supplies destination (berhasil→antar, berhasil-2→selesai).
06 login: complete (e1f4be2..9d26ef4, spec PASS / quality Approved) — Minors: default-step role tap always→busboy-selected (intended for busboy flavor); app golden still named home_screen.png; LoginStatusBar fake status bar may double with OS bar on device. Feature-first lib/features/auth/. LoginScreen({initialRole:LoginRole}); role_card.dart (enum LoginRole{tenan,busboy}). Bundled assets/images/{login-hero,role-tenan,role-busboy}.png (1x/2x/3x) in pubspec. Added theme heroGradientTop(#DCF9EB), cardSelectedFill(#F5FDF9), cardSelectedBorder(#B6E9D1). Established feature dir pattern: lib/features/<f>/presentation/{screens,widgets}/.
08 performa: complete (13e57b7..5e2c349, spec PASS / quality Approved, no findings). Built BOTH: PerformaScreen (/performa), PerformaV2Screen (/performa/v2) — two distinct layouts. lib/features/performa/{data/models,presentation/{screens,widgets,providers}}. Mock data via synchronous @riverpod performaV1DataProvider/performaV2DataProvider (TODO data source). Established: data/models/ dir + @riverpod provider pattern (build_runner). Added theme colors: header gradient, chart bars, accentBlue, accentAmber, starAmber, cardShadow.
11 akun: complete (00d4b1f..a450bc0, spec PASS / quality Approved) — Minors: theme statBlue dead (use accentBlue); golden-test comment overstates icon rendering (notdef boxes in committed golden). lib/features/akun/. Stubbed @riverpod akunAccountProvider (mock AkunAccount). Only 'Profil Saya' row wired → akunProfile; logout+others TODO. Added theme neutral300/neutralTint/hairline/dangerRed/dangerTint/statBlue.
>> DISCOVERY: `obra_icons` IS a project dependency — remaining screen items (07/09/10/12) should use ObraIcons.* for near-exact Figma icons instead of Material fallbacks. test/flutter_test_config.dart now loads the ObraIcons font (safe no-op fallback if asset absent).
07 menu-order: complete (1ac5e77..9ab125a, spec PASS / quality Approved) — Minors: barrier-dismiss on success modal still mutates state but skips onConfirm tab-switch (momentary inconsistency; move mutation into onConfirm or make non-dismissible); orderDetail always takes Baru[0] (single-mock, TODO). lib/features/order/. One OrderScreen hosts 3 sub-tabs via orderTabProvider + SegmentedTabBar (in-place). menu-order-baru-2 = OrderDetailScreen ('Detail Pesanan' + Ambil Pesanan CTA). @riverpod OrderBoardNotifier (mock, takeBaru/deliverAntar UI-only). Success modal: Ambil Pesanan→Antar tab, Sampai dimeja→Selesai tab. orderBerhasil/orderSelesaiBerhasil routes now redundant fallbacks. obra_icons: concierge-bell/hand-platter/phone-outgoing/timer NOT in obra 1.0.0 (Material fallback + TODO).
09 riwayat: complete (b2a064e..fd7d99a, spec PASS / quality Approved) — Minors: deep-link tab state persists/no reset + 1-frame flash (shared pattern w/ order _*TabDeepLink — seed tab in builder/redirect instead of post-frame); deep-link shim untested. lib/features/riwayat/. One RiwayatScreen + riwayatTabProvider + SegmentedTabBar. Built purpose-built HistoryRow (NOT OrderCard — riwayat card simpler). @riverpod riwayatDaysProvider(RiwayatRange) mock. Rows→goNamed(riwayatDetail). obra_icons filter/search/chevron.
10 detail: complete (6a3a435..436b263, spec PASS / quality Approved) — built across 2 sessions (1st died on API 401 mid-way, 2nd finished: fixed real 3px overflow in Alur Tugas cell + 2 lints + added goldens/tests). Minor: 'Jenis Layanan' section in tree.txt not in reference.png (built to reference — correct). Shared lib/core/widgets/completed_detail_view.dart + lib/core/models/completed_order_detail.dart for BOTH details (refs near-identical, differ only in 1 Informasi Pesanan value). @riverpod completedOrderDetail + riwayatDetail mock. Selesai card→orderSelesaiDetail wired in order_screen.dart. Bundled brand-kfc (1x/2x/3x).
12 profile-saya: complete (d2e6a08..e33f27b, spec PASS / quality Approved, no findings). lib/features/akun/. ProfileSayaScreen + BusboyProfile model + @riverpod busboyProfileProvider mock. Built local _ProfileField (read-only fill + dropdown + two-tone label variants AppInput lacks). akunProfile route→real screen; back→akun. Edit/Simpan UI-only stub (mock snackbar).

## ALL 12 ITEMS COMPLETE — 71 tests pass, flutter analyze clean.

## FINAL WHOLE-RUN REVIEW: READY (run base 4f2ffde .. cf96806)
- analyze 0 issues; flutter test 71/71 pass; build_runner 0 drift; all 17 frames reachable; login outside shell; 4 tabs correct; no regressions.
- Correction: 03 success700 is NOT dead (used in 9 sites across 06/07/08/11/12) — reviewer withdrew that Minor.
- Only concrete follow-up cleanup: 11 statBlue dead token (app_theme.dart:89) — deferred.
- All other Minors acceptable to defer (mock-stage UI tied to Open Questions):
  01(golden fixture named home_screen.png; Akun tab test path-only), 06(role-tap→busboy default [intended]; LoginStatusBar may double OS bar), 07(barrier-dismiss mutates state but skips onConfirm tab-switch — revisit when order-state logic lands; orderDetail always Baru[0]), 09(deep-link tab persists/1-frame flash; shim untested), 10(Jenis Layanan in tree.txt not in reference.png — built to reference), 11(golden comment overstates icon rendering).
- 2 intentional PlaceholderScreen routes remain: orderBerhasil, orderSelesaiBerhasil (redundant fallbacks; success is a dialog).

## RUN COMPLETE. No commit / no push (per user). Working tree holds all changes on branch feat/busboy-order-app.

## Route name/path map (established by item 01 — later items fill each route's builder only)
- login `/login` (login-default), loginTenant `/login/tenant` (login-tenantt) — OUTSIDE shell
- Order branch: order `/order` (menu-order-baru, post-login landing), orderDetail `/order/detail` (menu-order-baru-2), orderAntar `/order/antar` (menu-order-antar), orderBerhasil `/order/berhasil` (berhasil-ditambahkan), orderSelesai `/order/selesai` (menu-order-selesai), orderSelesaiDetail `/order/selesai/detail` (detail-selesai), orderSelesaiBerhasil `/order/selesai/berhasil` (berhasil-ditambahkan-2)
- Performa branch: performa `/performa` (performa-v1), performaV2 `/performa/v2` (performa-v2)
- Riwayat branch: riwayat `/riwayat` (riwayat-hari-ini), riwayatKemarin `/riwayat/kemarin`, riwayat7Hari `/riwayat/7-hari`, riwayatDetail `/riwayat/detail`
- Akun branch: akun `/akun`, akunProfile `/akun/profile` (profile-saya)
- Shell/nav: `lib/core/widgets/app_shell.dart` (StatefulShellRoute.indexedStack), `PlaceholderScreen` stub, `AppColors.successGreen/neutral500/neutral900/white` in app_theme.dart
