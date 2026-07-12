---
type: Work Item
title: Admin status (store online / offline)
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The Admin tab: store online/offline status screens with a toggle. `admin-offline` ⇄
`admin-online` (the Button toggles between them). Includes the status hero illustration.

## Required context

- Cached: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/admin-offline/` and `.../admin-online/`
  (reference.png + values.json + tree.txt).
- Prototype: `admin-offline` --(Button)--> `admin-online` and back; both link out to the
  other bottom-nav tabs.
- Uses the shared online/offline toggle widget (WI 02). Asset: `assets/admin-hero.png`.
- Icons via `obra_icons`.

## Acceptance criteria
- [x] Both `admin-offline` and `admin-online` reproduced from references.
- [x] Toggle switches between the two states.
- [x] Hosted under the Admin tab (WI 01).
- [x] Golden tests vs both references (self-goldens).

## Covers
- User-visible behavior: Admin status
- Interview Ledger: L5

## Blocked by
1

## Blocking decisions
- Open Questions 5, 6 (store-status data source, what "online/offline" gates) → mock state, UI-only toggle.
