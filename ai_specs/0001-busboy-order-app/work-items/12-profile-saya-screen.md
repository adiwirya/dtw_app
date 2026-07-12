---
type: Work Item
title: Profile Saya screen
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Profile Saya (my profile) screen: user profile detail, reached from Akun (WI 11).
390×1083 scrollable page.

## Required context

- Cached: `profile-saya/` (reference.png + values.json + tree.txt), 390×1083.
- Prototype: `profile-saya` --(back)--> `akun`.
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`.

## Acceptance criteria
- [x] `profile-saya` reproduced from its exported reference.
- [x] Navigation in from Akun wired (+ back → Akun).
- [x] Golden test vs the exported reference at 390px (self-golden).

## Covers
- User-visible behavior: Profile Saya
- Interview Ledger: L5

## Blocked by
11

## Blocking decisions
- Open Questions 1, 2 (profile data source, edit actions).
