---
type: Work Item
title: Order / Riwayat detail screens
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The detail views: `detail-riwayat` (history entry detail) and `detail-selesai`
(completed-order detail). Both are 390×950 scrollable detail pages.

## Required context

- Cached (each: reference.png + values.json + tree.txt): `detail-riwayat/` (390×950),
  `detail-selesai/` (390×950).
- Prototype: Riwayat rows --(tap)--> `detail-riwayat` --(back)--> `riwayat-7-hari`;
  `menu-order-selesai` --(tap row)--> `detail-selesai` --(back)--> `menu-order-selesai`.

## Acceptance criteria
- [x] Both detail screens reproduced from their exported references (shared CompletedDetailView).
- [x] Navigation in from Riwayat / Menu Order Selesai wired + back nav.
- [x] Golden tests vs each exported reference at 390px (self-goldens).

## Covers
- User-visible behavior: Riwayat detail, completed-order detail
- Interview Ledger: L5

## Blocked by
7, 9

## Blocking decisions
- Open Question 2 (detail data source).
