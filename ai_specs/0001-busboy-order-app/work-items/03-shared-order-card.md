---
type: Work Item
title: Shared — order card list item
parent: ../spec.md
---

## What to build

The reusable order card widget rendered in the Order list across all three sub-tabs
(Baru / Antar / Selesai) and referenced by the history/detail screens.

## Required context

- Appears on `menu-order-baru`, `menu-order-antar`, `menu-order-selesai` → one shared widget.
- Cached: `menu-order-baru/`, `menu-order-antar/`, `menu-order-selesai/` (reference.png +
  values.json + tree.txt). Tokens at `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`
  (card shadow `0 2 16 rgba(6,51,54,0.1)`, radius 12, white bg).

## Acceptance criteria
- [x] `OrderCard` widget matching the Menu Order frames; parameterized by status.
- [x] Widget test for layout + tap callback.

## Covers
- Requirements: shared components; Menu Order user-visible behavior
- Interview Ledger: L3

## Blocked by
None - ready to start
