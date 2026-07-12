---
type: Work Item
title: Performa dashboard screen
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Performa (performance) tab dashboard. Two layout variants exist in the design
(`performa-v1`, `performa-v2`); pick the intended one (Open Question) and build it.

## Required context

- Cached (reference.png + values.json + tree.txt): `performa-v1/` (390×844),
  `performa-v2/` (390×914).
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`.
- Note: nothing in the prototype navigates *to* `performa-v2` — likely a scroll/alt state.

## Acceptance criteria
- [x] Both Performa variants (v1 + v2) reproduced from their exported references. (Run decision: build both.)
- [x] Hosted under the Performa tab (WI 01) — routes `performa` `/performa` (v1), `performaV2` `/performa/v2` (v2).
- [x] Golden test for each (self-goldens; harness can't load Open Sans).

## Covers
- User-visible behavior: Performa
- Interview Ledger: L3

## Blocked by
1

## Blocking decisions
- Decide which variant is canonical (v1 vs v2), or whether v2 is a scroll state of v1.
- Open Question 2 (metrics data source).
