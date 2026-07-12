---
type: Work Item
title: Menu Order screen (Baru / Antar / Selesai)
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Order tab home: a list of orders with Baru / Antar / Selesai segmented sub-tabs.
Covers empty and populated states and the add/confirm → success-modal action.

## Required context

- Frames: `menu-order-baru` (1009:11609), `menu-order-baru-2` (1036:14101, alt state),
  `menu-order-antar` (1080:11466), `menu-order-selesai` (1117:3852).
- Cached (each: reference.png + values.json + tree.txt): `menu-order-baru/`,
  `menu-order-baru-2/`, `menu-order-antar/`, `menu-order-selesai/`.
- Prototype: `menu-order-baru` --(tap row)--> `menu-order-baru-2` --(back)--> `menu-order-baru`.
- Uses shared `OrderCard` (WI 03), `SegmentedTabBar` (WI 04), `SuccessModal` (WI 05).

## Acceptance criteria
- [x] Three sub-tabs render their order lists; segmented bar from WI 04.
- [x] Empty + populated states. (`menu-order-baru-2` = a full "Detail Pesanan" screen, not a list state.)
- [x] Add/confirm raises the shared success modal (onConfirm → correct sub-tab).
- [x] Golden tests vs each exported reference at 390px (self-goldens).

## Covers
- User-visible behavior: Menu Order
- Interview Ledger: L3, L5

## Blocked by
1, 3, 4, 5

## Blocking decisions
- Open Questions 2, 3, 4, 5 (data source, state transitions, empty/error/loading, pagination).
- Clarify the `menu-order-baru-2` state (expanded/detail vs. populated list) from its reference.
