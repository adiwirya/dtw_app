---
type: Work Item
title: Laporan (report dashboard)
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Laporan tab: a tall scrollable report dashboard (390×3402) with sales/order metrics,
charts, and breakdown sections.

## Required context

- Cached: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/laporan/` — `values.json` + `tree.txt`
  (full detail) and **`reference@0.5x.png`** (195×1701, half-res — @1x exceeded the export
  buffer). Build from tree.txt + values.json + the @0.5x visual.
- Assets: `assets/laporan-chart.png`, `assets/icon-cloud-download.svg`, `arrow-up-line.svg`.
- Prototype: reached via the Laporan (Imagine) bottom-nav icon from every main screen; links
  back out to the other tabs.
- Reuse chart/section patterns from the busboy Performa build (`lib/features/performa/`) if applicable.

## Acceptance criteria
- [x] `laporan` report dashboard reproduced from its cached (half-res) reference + tree/values.
- [x] Hosted under the Laporan tab (WI 01).
- [x] Golden test at 390px (self-golden). Note the @0.5x reference limits pixel-exact verification.

## Covers
- User-visible behavior: Laporan
- Interview Ledger: L2, L5

## Blocked by
1

## Blocking decisions
- Open Questions 5, 7 (report data source; @1x reference unavailable) → mock data + stubbed
  provider; verify layout against the @0.5x reference + tree.txt.
