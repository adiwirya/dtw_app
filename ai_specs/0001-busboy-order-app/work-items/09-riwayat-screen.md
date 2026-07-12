---
type: Work Item
title: Riwayat screen (Hari ini / Kemarin / 7 Hari)
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Riwayat (history) tab: a list of past orders with date tabs Hari ini / Kemarin /
7 Hari. Rows open a detail view (WI 10).

## Required context

- Cached (each: reference.png + values.json + tree.txt): `riwayat-hari-ini/`,
  `riwayat-kemarin/`, `riwayat-7-hari/`.
- Prototype: the three date tabs cross-link; rows on `riwayat-hari-ini` / `riwayat-7-hari`
  --(tap row)--> `detail-riwayat`.
- Uses shared `SegmentedTabBar` (WI 04).

## Acceptance criteria
- [x] Three date tabs render their history lists (in-place via SegmentedTabBar).
- [x] Rows navigate to `detail-riwayat` (WI 10) via goNamed(riwayatDetail).
- [x] Golden tests vs each exported reference at 390px (self-goldens).

## Covers
- User-visible behavior: Riwayat
- Interview Ledger: L3, L5

## Blocked by
1, 4

## Blocking decisions
- Open Questions 2, 4, 5 (history data source, empty/loading, pagination).
