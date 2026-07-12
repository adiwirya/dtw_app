---
type: Work Item
title: Orders flow (incoming / process / reject / complete)
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The tenant Order tab and its full flow: incoming orders → accept/reject (per item) →
process → complete, with a rejection-reason modal.

Covers frames: `menu-order-baru` (+`-2` state), `menu-diproses`, `pesanan-diproses`,
`pesanan-ditolak`, `konfirmasi-pesanan`, `alasan-penolakan` (modal), `selesai`.

## Required context

- Cached (each: reference.png + values.json + tree.txt) under
  `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/`: the 7 frames above.
- Prototype: `menu-order-baru` --> `menu-diproses` --> `selesai`; reject item(s) -->
  `pesanan-ditolak`; `alasan-penolakan` (modal) --(Button)--> `konfirmasi-pesanan`.
- Uses the shared incoming-order card (WI 02); reuse `SuccessModal` for confirmations.
- Design intent (L6): **orders can be rejected per item** — accept some items, reject others
  with a reason.

## Acceptance criteria
- [x] Order list (baru) + processing (diproses) + rejected (ditolak) + completed (selesai) screens reproduced.
- [x] Per-item accept/reject; rejection opens `alasan-penolakan` modal → `konfirmasi-pesanan`.
- [x] Hosted under the Order tab; navigation wired per the prototype.
- [x] Golden tests vs each reference at 390px (self-goldens).
- [x] Bottom nav reconciled to the menu-order-baru reference (raised-FAB Order); busboy untouched.

## Covers
- User-visible behavior: Orders
- Interview Ledger: L5, L6

## Blocked by
1, 2

## Blocking decisions
- Open Questions 2, 5, 6 (reject-per-item model, order data source, empty/error/loading) →
  mock data + stubbed provider, UI-only transitions.
