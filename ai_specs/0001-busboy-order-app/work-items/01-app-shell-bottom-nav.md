---
type: Work Item
title: App shell — routing + bottom navigation
parent: ../spec.md
---

## What to build

The busboy app shell: routing skeleton and a persistent 4-tab bottom navigation bar
(Order / Performa / Riwayat / Akun) that hosts the main screens. Routes stub to
placeholders for screens not yet built.

## Required context

- Flow map: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/manifest.json` (`flow`, inferred).
- Tabs → home routes: Order→`menu-order-baru`, Performa→`performa-v1`,
  Riwayat→`riwayat-hari-ini`, Akun→`akun`.
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json` (active tab `#10A760`).
- Flavor: busboy.

## Acceptance criteria
- [x] Bottom nav with 4 tabs (Order/Performa/Riwayat/Akun); active state uses success green.
- [x] Router (GoRouter or project convention) with named routes for all 17 frames; unbuilt routes stub.
- [x] Login is outside the shell; post-login lands on the Order tab (`menu-order-baru`).
- [x] Widget test asserts tab switching changes the hosted screen.

## Covers
- Requirements: bottom-nav shell; user-visible behavior (navigation)
- Interview Ledger: L1, L5

## Blocked by
None - ready to start
