---
type: Work Item
title: Login screen
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The login screen — a **2-step flow**: `login-default` shows the brand header ("DTW Order",
Pacifico wordmark) and "Masuk Sebagai" role cards (Tenan / Busboy); tapping a role reveals
`login-tenantt` with the username + password inputs, "Ingat Saya" checkbox, "Lupa Password?"
link, and "Masuk" primary button that routes to `menu-order-baru`.

## Required context

- Cached: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/login-default/` and `.../login-tenantt/`
  (reference.png @1x + values.json + tree.txt each). ✅
- Prototype flow: `login-default` --(tap role card)--> `login-tenantt` --(Masuk)--> `menu-order-baru`.
- Assets: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/assets/` — `login-hero@2x/3x.png`,
  `role-tenan@2x/3x.png`, `role-busboy@2x/3x.png`, `icon-user-round.svg`,
  `icon-lock-keyhole.svg`, `icon-eye.svg`, `icon-square.svg`.
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`.
- Fonts: Open Sans, Pacifico ("Order"), Inter (status bar).

## Acceptance criteria
- [x] Both `login-default` and `login-tenantt` reproduced from cached references.
- [x] Uses shared `AppInput` + `PrimaryButton` (WI 02).
- [x] Busboy role card is the primary CTA for this flavor; "Masuk" routes to the Order tab.
- [x] Golden tests vs `login-default/reference.png` and `login-tenantt/reference.png` at 390px (self-goldens; harness can't load Open Sans).

## Covers
- User-visible behavior: Login (2-step)
- Interview Ledger: L1, L2, L5
- Cache: login-default, login-tenantt (reference.png ✅, values.json ✅)

## Blocked by
2

## Blocking decisions
- Open Question 1 (auth, and whether the Tenan role is in scope for this busboy build) may
  reduce this screen to Busboy-only.
