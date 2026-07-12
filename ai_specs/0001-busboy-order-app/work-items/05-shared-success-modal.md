---
type: Work Item
title: Shared — "Berhasil ditambahkan" success modal
parent: ../spec.md
---

## What to build

The reusable success/confirmation modal ("berhasil ditambahkan"), a 358×426 overlay
shown after an order action. Appears twice in the design → one shared widget.

## Required context

- Frames: `berhasil-ditambahkan` (1080:11394), `berhasil-ditambahkan-2` (1117:3805).
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`.

## Acceptance criteria
- [x] `SuccessModal` widget (dialog/bottom sheet per exported design), dismissible.
- [x] Widget test asserting it shows and dismisses.

## Covers
- Requirements: shared components; Menu Order success flow
- Interview Ledger: L3

## Blocked by
None - ready to start

## Blocking decisions
- Per the prototype, the two modal instances lead to different screens: `berhasil-ditambahkan`
  → `menu-order-antar`, `berhasil-ditambahkan-2` → `menu-order-selesai`. Confirm whether the
  modal itself is one widget shown in two flows (recommended) vs. two variants.
