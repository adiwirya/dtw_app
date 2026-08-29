import 'dart:async';

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/tenant_shell.dart';
import 'package:dtw_app/features/tenant/presentation/screens/admin_status_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/kelola_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/laporan_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/menu_saya_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/pilih_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_detail_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_reject_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/kelola_menu_sheet.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_success_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/opsi_varian_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_confirmed_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_reason_sheet.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Named routes for the tenant shell, mounted inside the single merged
/// `GoRouter` in `app_router.dart` (see [tenantShellRoute]) — there is no
/// separate tenant router or tenant login route; a signed-in tenant session
/// (`sessionBranchIdProvider` non-null, see `core/flavor.dart`) just lands on
/// [orderPath] instead of the busboy `AppRoutes.orderPath`.
///
/// Every one of the 34 tenant frames (see the tenant Figma manifest `screens`)
/// gets a stable route name + path here. Screens not yet built render a
/// placeholder; later tenant work items swap the `builder:` for the real screen
/// while keeping the name/path stable, so `context.goNamed(...)` callers never
/// change.
///
/// Comment after each constant is the manifest `slug` it maps to.
abstract class TenantRoutes {
  // --- Tab 0: Order (home = menu-order-baru) ---
  static const order = 'tenantOrder'; // menu-order-baru
  static const orderDetail = 'tenantOrderDetail'; // menu-order-baru-2
  static const menuDiproses = 'tenantMenuDiproses'; // menu-diproses
  static const pesananDiproses = 'tenantPesananDiproses'; // pesanan-diproses
  static const pesananDitolak = 'tenantPesananDitolak'; // pesanan-ditolak
  static const konfirmasiPesanan =
      'tenantKonfirmasiPesanan'; // konfirmasi-pesanan
  static const alasanPenolakan =
      'tenantAlasanPenolakan'; // alasan-penolakan (modal)
  static const selesai = 'tenantSelesai'; // selesai
  static const pesananBerhasil =
      'tenantPesananBerhasil'; // berhasil-ditambahkan-2 (modal)

  // --- Tab 1: Menu Saya (home = menu-saya) ---
  static const menuSaya = 'tenantMenuSaya'; // menu-saya
  static const menuSayaV2 = 'tenantMenuSayaV2'; // menu-saya-2
  static const menuBerhasil = 'tenantMenuBerhasil'; // menu-berhasil-ditambahkan
  static const tambahMenu = 'tenantTambahMenu'; // tambah-menu
  static const menuDiisi = 'tenantMenuDiisi'; // menu-diisi
  static const kelolaMenu = 'tenantKelolaMenu'; // kelola-menu (modal)
  static const kelolaMenu2 = 'tenantKelolaMenu2'; // kelola-menu-2 (modal)
  static const berhasilDitambahkan =
      'tenantBerhasilDitambahkan'; // berhasil-ditambahkan (modal)
  // Varian editing sub-flow (still under the Menu Saya tab).
  static const kelolaVarian = 'tenantKelolaVarian'; // kelola-varian
  static const varianDitambahkan =
      'tenantVarianDitambahkan'; // varian-ditambahkan
  static const varianDisimpan = 'tenantVarianDisimpan'; // varian-disimpan
  static const tambahVarian = 'tenantTambahVarian'; // tambah-varian
  static const tambahVarian2 = 'tenantTambahVarian2'; // tambah-varian-2
  static const varianDiisi = 'tenantVarianDiisi'; // varian-diisi
  static const tambahOpsi2 = 'tenantTambahOpsi2'; // tambah-opsi-2
  static const opsi2Ditambahkan =
      'tenantOpsi2Ditambahkan'; // opsi-2-ditambahkan
  static const opsiVarian1 = 'tenantOpsiVarian1'; // opsi-varian-1 (modal)
  static const opsiVarian1Diisi =
      'tenantOpsiVarian1Diisi'; // opsi-varian-1-diisi (modal)
  static const opsiVarian2Diisi =
      'tenantOpsiVarian2Diisi'; // opsi-varian-2-diisi (modal)
  static const opsiVarian2Diisi2 =
      'tenantOpsiVarian2Diisi2'; // opsi-varian-2-diisi-2 (modal)

  // --- Tab 2: Laporan (home = laporan) ---
  static const laporan = 'tenantLaporan'; // laporan

  // --- Tab 3: Admin (home = admin-offline) ---
  static const admin = 'tenantAdmin'; // admin-offline
  static const adminOnline = 'tenantAdminOnline'; // admin-online

  // Absolute paths referenced from outside the router. Prefixed under
  // `/tenant` since they share one `GoRouter` with `AppRoutes`, whose Order
  // tab already owns the unprefixed `/order`.
  static const orderPath = '/tenant/order';
  static const menuSayaPath = '/tenant/menu-saya';
  static const laporanPath = '/tenant/laporan';
  static const adminPath = '/tenant/admin';
}

/// Deep-link wrapper for `/order/alasan-penolakan`: presents the reason-capture
/// sheet as a page (the in-flow UX is a bottom sheet from the reject screen).
class _AlasanPenolakanRouteScreen extends StatelessWidget {
  const _AlasanPenolakanRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            child: RejectReasonSheet(
              item: OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deep-link wrapper for `/order/pesanan-berhasil`: raises the rejection
/// confirmation dialog (the in-flow UX raises it from the reject screen).
class _PesananBerhasilRouteScreen extends StatefulWidget {
  const _PesananBerhasilRouteScreen();

  @override
  State<_PesananBerhasilRouteScreen> createState() =>
      _PesananBerhasilRouteScreenState();
}

class _PesananBerhasilRouteScreenState
    extends State<_PesananBerhasilRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showRejectConfirmedModal(
          context,
          acceptedCount: 1,
          rejectedCount: 1,
          acceptedTotal: 'Rp35.000',
          onConfirm: () => context.goNamed(TenantRoutes.pesananDiproses),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.white);
}

/// Deep-link wrapper for `/menu-saya/kelola` (`kelola-menu` / `-2`): raises the
/// Kelola Menu bottom sheet over the Menu Saya list. The in-flow UX raises it
/// from the list's "Kelola Menu" action.
class _KelolaMenuRouteScreen extends StatefulWidget {
  const _KelolaMenuRouteScreen();

  @override
  State<_KelolaMenuRouteScreen> createState() => _KelolaMenuRouteScreenState();
}

class _KelolaMenuRouteScreenState extends State<_KelolaMenuRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showKelolaMenuSheet(
          context,
          onTambahMenu: () => context.goNamed(TenantRoutes.tambahMenu),
          onKelolaVarian: () => context.goNamed(TenantRoutes.kelolaVarian),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const MenuSayaScreen();
}

/// Deep-link wrapper for `/menu-saya/berhasil-modal` (`berhasil-ditambahkan`):
/// raises the menu-added success modal, then advances to the updated list.
class _BerhasilDitambahkanRouteScreen extends StatefulWidget {
  const _BerhasilDitambahkanRouteScreen();

  @override
  State<_BerhasilDitambahkanRouteScreen> createState() =>
      _BerhasilDitambahkanRouteScreenState();
}

class _BerhasilDitambahkanRouteScreenState
    extends State<_BerhasilDitambahkanRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showMenuSuccessModal(
          context,
          onConfirm: () => context.goNamed(TenantRoutes.menuBerhasil),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const MenuSayaScreen();
}

/// The one option seeded on `tambah-opsi-2` (`Small`, free => `Gratis`).
const _smallOption = VariantOptionData(name: 'Small');

/// The two options seeded on `opsi-2-ditambahkan` (adds `Medium` +Rp3.000).
const List<VariantOptionData> _twoOptions = [
  _smallOption,
  VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
];

/// Opens the `opsi-varian-1` option modal over the current variant form; on
/// Simpan advances to the [next] named route (the option flow's forward edge).
void _openOpsiVarianModal(
  BuildContext context, {
  required String next,
  String initialName = '',
  String initialPrice = '',
}) {
  unawaited(
    showOpsiVarianModal(
      context,
      initialName: initialName,
      initialPrice: initialPrice,
    ).then((option) {
      if (option != null && context.mounted) context.goNamed(next);
    }),
  );
}

/// Deep-link wrapper for the `opsi-varian-1*` modal frames: raises the option
/// modal over a variant-form backdrop; Simpan advances to [next] per the
/// prototype (`opsi-varian-1-diisi` → `tambah-opsi-2`, `opsi-varian-2-diisi-2`
/// → `opsi-2-ditambahkan`).
class _OpsiVarianRouteScreen extends StatefulWidget {
  const _OpsiVarianRouteScreen({
    required this.next,
    this.initialName = '',
    this.initialPrice = '',
    this.backdropOptions = const [],
  });

  final String next;
  final String initialName;
  final String initialPrice;
  final List<VariantOptionData> backdropOptions;

  @override
  State<_OpsiVarianRouteScreen> createState() => _OpsiVarianRouteScreenState();
}

class _OpsiVarianRouteScreenState extends State<_OpsiVarianRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showOpsiVarianModal(
          context,
          initialName: widget.initialName,
          initialPrice: widget.initialPrice,
        ).then((option) {
          if (option == null || !mounted) return;
          context.goNamed(widget.next);
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) => TambahVarianScreen(
    prefilled: true,
    options: widget.backdropOptions,
  );
}

/// The tenant persistent 4-tab bottom-nav shell (Order / Menu Saya / Laporan /
/// Admin), mounted as one branch of the single merged `GoRouter` in
/// `app_router.dart` alongside the busboy shell.
StatefulShellRoute tenantShellRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        TenantShell(navigationShell: navigationShell),
    branches: [
      // Tab 0 — Order (home = menu-order-baru).
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: TenantRoutes.orderPath,
            name: TenantRoutes.order,
            builder: (context, state) => const TenantOrderScreen(),
            routes: [
              // menu-order-baru-2: the Order view reached from a card
              // tap (a prototype duplicate of the Baru home).
              GoRoute(
                path: 'baru-2/:orderId',
                name: TenantRoutes.orderDetail,
                builder: (context, state) => TenantOrderDetailScreen(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
              // menu-diproses: the same Order home seeded to the
              // "Diproses" sub-tab.
              GoRoute(
                path: 'diproses',
                name: TenantRoutes.menuDiproses,
                builder: (context, state) => const TenantOrderScreen(
                  initialStatus: IncomingOrderStatus.diproses,
                ),
              ),
              // pesanan-diproses: same Diproses sub-tab view.
              GoRoute(
                path: 'pesanan-diproses',
                name: TenantRoutes.pesananDiproses,
                builder: (context, state) => const TenantOrderScreen(
                  initialStatus: IncomingOrderStatus.diproses,
                ),
              ),
              // pesanan-ditolak: the reject screen for ONE real order.
              //
              // The order id is a path parameter, not `extra`: it is the
              // whole identity of the screen, so it has to survive a deep
              // link / process restart (`extra` does not), and the screen
              // reads every other value it shows off the board entry for
              // this id. Before it was threaded through, the screen fell
              // back to a hardcoded id and its confirm flow silently
              // no-oped against an order that did not exist.
              GoRoute(
                path: 'ditolak/:orderId',
                name: TenantRoutes.pesananDitolak,
                builder: (context, state) => TenantRejectOrderScreen(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
              // konfirmasi-pesanan: the same reject screen deep-linked to
              // its some-items-rejected state. The seed is prototype frame
              // state (like `initialStatus` / `prefilled` elsewhere in this
              // router), not order data.
              GoRoute(
                path: 'konfirmasi/:orderId',
                name: TenantRoutes.konfirmasiPesanan,
                builder: (context, state) => TenantRejectOrderScreen(
                  orderId: state.pathParameters['orderId']!,
                  seedFirstItemRejected: true,
                ),
              ),
              // alasan-penolakan (modal): reason capture. Primary UX is a
              // bottom sheet raised from the reject screen; this route is
              // a deep-link entry rendering the same sheet as a page.
              GoRoute(
                path: 'alasan-penolakan',
                name: TenantRoutes.alasanPenolakan,
                builder: (context, state) =>
                    const _AlasanPenolakanRouteScreen(),
              ),
              // selesai: same Order home seeded to the "Selesai" sub-tab.
              GoRoute(
                path: 'selesai',
                name: TenantRoutes.selesai,
                builder: (context, state) => const TenantOrderScreen(
                  initialStatus: IncomingOrderStatus.selesai,
                ),
              ),
              // berhasil-ditambahkan-2 (modal): rejection confirmation.
              // Primary UX is a dialog raised from the reject screen;
              // this route is a deep-link entry presenting that dialog.
              GoRoute(
                path: 'pesanan-berhasil',
                name: TenantRoutes.pesananBerhasil,
                builder: (context, state) =>
                    const _PesananBerhasilRouteScreen(),
              ),
            ],
          ),
        ],
      ),

      // Tab 1 — Menu Saya (home = menu-saya).
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: TenantRoutes.menuSayaPath,
            name: TenantRoutes.menuSaya,
            builder: (context, state) => const MenuSayaScreen(),
            routes: [
              GoRoute(
                path: 'v2',
                name: TenantRoutes.menuSayaV2,
                builder: (context, state) => const MenuSayaScreen(),
              ),
              // menu-berhasil-ditambahkan: the list after a successful
              // add (header → "+ Tambah Menu", new row shown).
              GoRoute(
                path: 'berhasil',
                name: TenantRoutes.menuBerhasil,
                builder: (context, state) =>
                    const MenuSayaScreen(recentlyAdded: true),
              ),
              GoRoute(
                path: 'tambah',
                name: TenantRoutes.tambahMenu,
                builder: (context, state) => const TambahMenuScreen(),
              ),
              // menu-diisi: edit an existing menu — the real product id is a
              // path parameter (see the `ditolak/:orderId` comment above for
              // why: it is the screen's whole identity). This used to render
              // the form on a hardcoded "Paket Komplit" seed, so every menu
              // row opened the same fake product.
              GoRoute(
                path: 'diisi/:productId',
                name: TenantRoutes.menuDiisi,
                builder: (context, state) => TambahMenuScreen(
                  editingProductId: state.pathParameters['productId'],
                ),
              ),
              // kelola-menu (modal): Tambah Menu / Kelola Varian chooser.
              GoRoute(
                path: 'kelola',
                name: TenantRoutes.kelolaMenu,
                builder: (context, state) => const _KelolaMenuRouteScreen(),
              ),
              GoRoute(
                path: 'kelola-2',
                name: TenantRoutes.kelolaMenu2,
                builder: (context, state) => const _KelolaMenuRouteScreen(),
              ),
              // berhasil-ditambahkan (modal): menu-added confirmation.
              GoRoute(
                path: 'berhasil-modal',
                name: TenantRoutes.berhasilDitambahkan,
                builder: (context, state) =>
                    const _BerhasilDitambahkanRouteScreen(),
              ),
              // kelola-varian: the variant manage screen (empty state).
              GoRoute(
                path: 'varian',
                name: TenantRoutes.kelolaVarian,
                builder: (context, state) => const KelolaVarianScreen(),
              ),
              // varian-ditambahkan: the menu form with the picked
              // variants attached; back returns to
              // menu-berhasil-ditambahkan (prototype).
              GoRoute(
                path: 'varian-ditambahkan',
                name: TenantRoutes.varianDitambahkan,
                // The variants picked on `PilihVarianScreen` reach the form
                // through `menuVariantSelectionProvider`, not this route.
                builder: (context, state) => TambahMenuScreen(
                  prefilled: true,
                  onBack: () => context.goNamed(TenantRoutes.menuBerhasil),
                ),
              ),
              // varian-disimpan: the same manage screen as kelola-varian
              // — now real data, it shows the filled state on its own
              // once the tenant has saved variants.
              GoRoute(
                path: 'varian-disimpan',
                name: TenantRoutes.varianDisimpan,
                builder: (context, state) => const KelolaVarianScreen(),
              ),
              // tambah-varian: the "Pilih Varian" picker (attach existing
              // variants); "Tambah" advances to varian-ditambahkan.
              GoRoute(
                path: 'tambah-varian',
                name: TenantRoutes.tambahVarian,
                builder: (context, state) => const PilihVarianScreen(),
              ),
              // tambah-varian-2: the real "Buat Varian" entry point (from
              // the empty kelola-varian screen) — the default "+ Tambah
              // Opsi" (local modal) and "Simpan Varian" (real save via
              // VariantList.create) behaviour applies, so nothing is
              // overridden here.
              GoRoute(
                path: 'tambah-varian-2',
                name: TenantRoutes.tambahVarian2,
                builder: (context, state) => const TambahVarianScreen(),
              ),
              // varian-diisi: edit an existing variant — the real modifier
              // group id is a path parameter (see the `ditolak/:orderId`
              // comment above for why: it's the screen's whole identity).
              GoRoute(
                path: 'varian-diisi/:variantId',
                name: TenantRoutes.varianDiisi,
                builder: (context, state) => TambahVarianScreen(
                  editingVariantId: state.pathParameters['variantId'],
                ),
              ),
              // tambah-opsi-2: the variant form with one option (Small /
              // Gratis) added; Simpan Varian → varian-ditambahkan.
              GoRoute(
                path: 'tambah-opsi-2',
                name: TenantRoutes.tambahOpsi2,
                builder: (context, state) => TambahVarianScreen(
                  prefilled: true,
                  options: const [_smallOption],
                  onSave: () => context.goNamed(TenantRoutes.varianDitambahkan),
                  onTambahOpsi: (ctx) => _openOpsiVarianModal(
                    ctx,
                    next: TenantRoutes.opsi2Ditambahkan,
                  ),
                ),
              ),
              // opsi-2-ditambahkan: the variant form with two options
              // (Small / +Rp3.000 Medium); Simpan Varian → varian-disimpan.
              GoRoute(
                path: 'opsi-2-ditambahkan',
                name: TenantRoutes.opsi2Ditambahkan,
                builder: (context, state) => TambahVarianScreen(
                  prefilled: true,
                  options: _twoOptions,
                  onSave: () => context.goNamed(TenantRoutes.varianDisimpan),
                  onTambahOpsi: (ctx) => _openOpsiVarianModal(
                    ctx,
                    next: TenantRoutes.opsi2Ditambahkan,
                  ),
                ),
              ),
              // opsi-varian-1 (modal): empty option add form; Simpan →
              // tambah-opsi-2.
              GoRoute(
                path: 'opsi-varian-1',
                name: TenantRoutes.opsiVarian1,
                builder: (context, state) => const _OpsiVarianRouteScreen(
                  next: TenantRoutes.tambahOpsi2,
                ),
              ),
              // opsi-varian-1-diisi (modal): filled (Small / 0); Simpan →
              // tambah-opsi-2.
              GoRoute(
                path: 'opsi-varian-1-diisi',
                name: TenantRoutes.opsiVarian1Diisi,
                builder: (context, state) => const _OpsiVarianRouteScreen(
                  next: TenantRoutes.tambahOpsi2,
                  initialName: 'Small',
                  initialPrice: '0',
                ),
              ),
              // opsi-varian-2-diisi (modal): the second option's empty
              // form over the one-option backdrop; Simpan → opsi-2-...
              GoRoute(
                path: 'opsi-varian-2-diisi',
                name: TenantRoutes.opsiVarian2Diisi,
                builder: (context, state) => const _OpsiVarianRouteScreen(
                  next: TenantRoutes.opsi2Ditambahkan,
                  backdropOptions: [_smallOption],
                ),
              ),
              // opsi-varian-2-diisi-2 (modal): filled (Medium / 3000);
              // Simpan → opsi-2-ditambahkan.
              GoRoute(
                path: 'opsi-varian-2-diisi-2',
                name: TenantRoutes.opsiVarian2Diisi2,
                builder: (context, state) => const _OpsiVarianRouteScreen(
                  next: TenantRoutes.opsi2Ditambahkan,
                  initialName: 'Medium',
                  initialPrice: '3000',
                  backdropOptions: [_smallOption],
                ),
              ),
            ],
          ),
        ],
      ),

      // Tab 2 — Laporan (home = laporan).
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: TenantRoutes.laporanPath,
            name: TenantRoutes.laporan,
            builder: (context, state) => const LaporanScreen(),
          ),
        ],
      ),

      // Tab 3 — Admin (home = admin-offline).
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: TenantRoutes.adminPath,
            name: TenantRoutes.admin,
            builder: (context, state) => const AdminStatusScreen(),
            routes: [
              // admin-online: same screen as admin-offline — the
              // online/offline distinction was removed (no real toggle
              // ever set it), so both frames render identically. The
              // route stays for frame-route stability.
              GoRoute(
                path: 'online',
                name: TenantRoutes.adminOnline,
                builder: (context, state) => const AdminStatusScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
