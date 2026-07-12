---
type: Spec
title: DTW Order — Tenant (Merchant) app (UI from Figma)
---

# DTW Order — Tenant / Merchant

## Problem

The tenant (merchant/seller) side of DTW Order needs its Flutter UI built. A HIFI Figma
design (page 🟡 HIFI Tenant, file `CPWCfPomucIUq4k7hZwtwM`) defines 34 frames covering
login, incoming-order management (accept/reject/process), store online/offline status,
menu management, variant/option management, and reports. This Spec turns that design into
per-feature Work Items that build offline from a local Figma cache.

## Proposed outcome

A Flutter **tenant flavor** of the app (separate build entrypoint from busboy) that
reproduces the Figma screens pixel-faithfully: 2-step login, a 4-tab bottom-nav shell
(Order / Menu Saya / Laporan / Admin), incoming-order flow with per-item reject, store
open/close toggle, menu + variant CRUD, and a report dashboard.

## Constraints & technical decisions

- **Flavor:** tenant (L1). Built as a **separate product flavor** — a `main_tenant.dart`
  entrypoint with its own shell/router, alongside the existing busboy app (L3). The project
  currently only has environment flavors (`dev`/`prod`); this introduces the tenant product
  flavor.
- **Offline-first build:** implementation and pixel verification read only the local cache
  at `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/` — never live Figma.
- **Reuse existing shared widgets** where they fit (built during the busboy work):
  `lib/core/widgets/` `AppInput`, `PrimaryButton`, `SegmentedTabBar`, `SuccessModal`,
  and the theme in `lib/core/theme/app_theme.dart`. Icons via `obra_icons`.
- **Cache complete:** all 34 frames harvested (reference.png + values.json + tree.txt) +
  40 shared assets. `laporan/reference@0.5x.png` is half-res (195×1701) — build from its
  tree.txt + values.json + the @0.5x visual.

## User-visible behavior (from design)

- **Login** (2-step): `login-default` (role cards) → tap Tenan → `login-tenantt` (form) →
  Masuk → `menu-order-baru`.
- **Orders** (Order tab): incoming orders (`menu-order-baru` +`-2`), processing
  (`menu-diproses`/`pesanan-diproses`), rejected (`pesanan-ditolak`) with a rejection-reason
  modal (`alasan-penolakan`) → `konfirmasi-pesanan`, and completed (`selesai`). **Orders can
  be rejected per item** (L6).
- **Admin** (Admin tab): store online/offline toggle (`admin-offline` ⇄ `admin-online`).
- **Menu Saya** (Menu Saya tab): menu list (`menu-saya`), add menu (`tambah-menu`,
  `menu-diisi`, `menu-berhasil-ditambahkan`), manage (`kelola-menu`), success modals
  (`berhasil-ditambahkan`).
- **Variants**: manage/add variants & options (`kelola-varian`, `tambah-varian`,
  `varian-diisi`, `varian-ditambahkan`, `varian-disimpan`, `tambah-opsi-2`,
  `opsi-2-ditambahkan`, `opsi-varian-1/2`). Options are **required + multi-select** with
  **"+price"** (L6).
- **Laporan** (Laporan tab): report dashboard.

## Design tokens

Cached at `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/tokens.json` (figma-cli var list =
names+types; concrete values in each screen's values.json). Reuse `app_theme.dart` tokens.

## Testing strategy

- Widget tests per feature for layout/structure and static copy.
- Golden/self-golden comparison against each `reference.png` at frame width.

## Scope boundaries

- **In scope:** UI construction of the 34 tenant frames + tenant flavor shell + tenant-specific shared widgets.
- **Out of scope (this Spec):** backend/API wiring, auth, real data, business logic — Open Questions, not invented.

## Open Questions

1. **Flavor split mechanics:** does the existing busboy app get refactored into a `busboy`
   flavor, or does tenant add a parallel `main_tenant.dart` entrypoint leaving busboy as the
   default? (Resolve in the shell item.)
2. **Order reject-per-item:** the data model + logic for rejecting individual items in an
   order, the rejection-reason capture, and the resulting order state.
3. **Menu requirements (design note, L6):** "best seller" → **PIN/Popular** labeling;
   **promo removed**; **2 discount fields** (percentage + price + valid date); **stock
   availability removed**. Exact field semantics/validation unknown.
4. **Variant/option requirements (L6):** options **required + multi-select**, with a
   **"+price"** add-on per option. Validation rules unknown.
5. **Data sources / APIs** for orders, menu, variants, and reports.
6. **Auth**, and **empty / error / loading states** for every list — not in the design.
7. **`laporan` @1x reference** is unavailable (buffer limit) — half-res only; pixel-exact
   verification of the tall report is limited.

See `interview-ledger.md` for decisions (L1–L6). Resolve Open Questions via `/ftk-interview`.
