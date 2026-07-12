---
type: Work Item
title: Variant / option management
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The variant & option management flow reached from menu management: create variants, add
options, fill option details, save.

Covers frames: `kelola-varian`, `tambah-varian` (+`-2`), `varian-diisi`, `varian-ditambahkan`,
`varian-disimpan`, `tambah-opsi-2`, `opsi-2-ditambahkan`, `opsi-varian-1` (+`-diisi`),
`opsi-varian-2-diisi` (+`-2`).

## Required context

- Cached (each: reference.png + values.json + tree.txt) under
  `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/`: the frames above (several 358-wide option modals).
- Prototype: `kelola-varian` --> `tambah-varian`; `tambah-varian` --> `varian-ditambahkan`;
  `tambah-opsi-2` --> `varian-ditambahkan`; `opsi-2-ditambahkan` --> `varian-disimpan`;
  `opsi-varian-1-diisi` --> `tambah-opsi-2`; `varian-ditambahkan` --(back)--> `menu-berhasil-ditambahkan`.
- Uses shared variant/option row widgets (WI 02); reuse `AppInput`, `PrimaryButton`.
- **Design intent (L6)** — options are **required + multi-select** (choose more than one),
  each option has a **"+price"** add-on (e.g. the spicy option).

## Acceptance criteria
- [x] Variant list/create, add-option (empty + filled), and save states reproduced.
- [x] Options modeled as **required multi-select** with a per-option **"+price"** field (L6).
- [x] Navigation wired per the prototype (from menu management through save).
- [x] Golden tests vs each reference at 390px (self-goldens; 358-wide modals at their size).

## Covers
- User-visible behavior: variant/option management
- Interview Ledger: L5, L6

## Blocked by
6

## Blocking decisions
- Open Questions 4, 5 (option multi-select/+price validation, variant data source) →
  mock data + stubbed provider.
