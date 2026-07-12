---
type: Work Item
title: Menu management
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Menu Saya tab and menu CRUD: menu list, add/fill menu, manage menu, success modals.

Covers frames: `menu-saya` (+`-2`), `tambah-menu` (390×1382), `menu-diisi` (390×1382),
`menu-berhasil-ditambahkan`, `kelola-menu` (+`-2`, modals), `berhasil-ditambahkan` (+`-2`, modals).

## Required context

- Cached (each: reference.png + values.json + tree.txt) under
  `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/`: the frames above.
- Prototype: `menu-saya` (nav home = Search icon); `tambah-menu` --> `menu-diisi` -->
  (variants, WI 07); `kelola-menu` modal --> `kelola-varian` / `tambah-menu`;
  `berhasil-ditambahkan` modal --> `menu-berhasil-ditambahkan`.
- Uses shared menu-item card (WI 02); reuse `AppInput`, `PrimaryButton`, `SuccessModal`.
- **Design intent (L6)** — apply on the menu form: "best seller" label → **PIN/Popular**;
  **promo removed**; **2 discount fields** (percentage + price + valid date);
  **stock availability removed**.

## Acceptance criteria
- [x] Menu list, add-menu (empty + filled), manage-menu modal, and success modals reproduced.
- [x] Menu form reflects the L6 requirements (PIN/Popular, discount fields, no stock, no promo).
- [x] Hosted under the Menu Saya tab; "add variant" navigates into WI 07.
- [x] Golden tests vs each reference at 390px (self-goldens).

## Covers
- User-visible behavior: Menu Saya / menu CRUD
- Interview Ledger: L5, L6

## Blocked by
1, 2

## Blocking decisions
- Open Questions 3, 5, 6 (menu field semantics/validation, menu data source, empty/error/loading) →
  mock data + stubbed provider.
