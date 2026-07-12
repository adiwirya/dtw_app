---
type: Work Item
title: Shared — segmented tab bar
parent: ../spec.md
---

## What to build

A reusable segmented tab bar widget used by the Order screen (Baru / Antar / Selesai)
and the Riwayat screen (Hari ini / Kemarin / 7 Hari).

## Required context

- Used on `menu-order-*` and `riwayat-*` → one shared widget.
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json` (active `#10A760`, inactive `#667085`).

## Acceptance criteria
- [x] `SegmentedTabBar` widget: N labeled segments, selected index, onChanged callback.
- [x] Active/inactive styling from tokens.
- [x] Widget test for selection + callback.

## Covers
- Requirements: shared components; Menu Order + Riwayat behavior
- Interview Ledger: L3

## Blocked by
None - ready to start
