---
type: Work Item
title: Akun screen
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Akun (account) tab: account menu/summary that links to Profile Saya (WI 12) and
other account actions.

## Required context

- Cached: `akun/` (reference.png + values.json + tree.txt), 390×844.
- Prototype: `akun` --(tap profile)--> `profile-saya`.
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`.

## Acceptance criteria
- [x] `akun` reproduced from its exported reference.
- [x] Hosted under the Akun tab (WI 01); navigates to Profile Saya.
- [x] Golden test vs the exported reference at 390px (self-golden).

## Covers
- User-visible behavior: Akun
- Interview Ledger: L5

## Blocked by
1

## Blocking decisions
- Open Question 1 (logout / auth actions).
