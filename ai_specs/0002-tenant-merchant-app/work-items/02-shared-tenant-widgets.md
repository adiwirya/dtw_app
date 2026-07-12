---
type: Work Item
title: Shared tenant widgets
parent: ../spec.md
---

## What to build

Tenant-specific reusable widgets, plus reuse of existing shared widgets. Build the elements
that appear across more than one tenant screen:

- **Incoming-order card** (per-item accept/reject) — used across the Order flow.
- **Menu-item card** — used in Menu Saya list + management.
- **Variant / option row** widgets — used across the variant-management screens.
- **Online/offline status toggle** — used on the Admin screens.

Reuse existing (do NOT rebuild): `AppInput`, `PrimaryButton`, `SegmentedTabBar`,
`SuccessModal` (`lib/core/widgets/`).

## Required context

- Study references under `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/`: `menu-order-baru/`,
  `menu-diproses/`, `pesanan-ditolak/` (order card); `menu-saya/`, `tambah-menu/` (menu card);
  `tambah-varian/`, `varian-diisi/`, `opsi-varian-1/` (variant/option rows); `admin-offline/`,
  `admin-online/` (toggle).
- Design intent (L6): orders **reject-per-item**; variant options **required + multi-select**
  with a **"+price"** add-on.
- Tokens: `app_theme.dart` + each screen's `values.json`. Icons: `obra_icons`.

## Acceptance criteria
- [x] Incoming-order card (status + per-item accept/reject affordance), parameterized.
- [x] Menu-item card, parameterized (name, price, PIN/Popular label per L6, discount).
- [x] Variant/option row widgets (multi-select option, "+price").
- [x] Online/offline status toggle widget.
- [x] Widget tests for each (layout + callbacks).

## Covers
- Requirements: shared tenant components
- Interview Ledger: L4, L6

## Blocked by
None - ready to start

## Blocking decisions
- Open Questions 2, 3, 4 (reject-per-item model, menu discount/label fields, option
  multi-select/+price rules) affect these widgets' data shape — build UI with mock params, stub logic.
