---
type: Work Item
title: Login (tenant, 2-step)
parent: ../spec.md
---

Build via: /ftk-build-ui

## What to build

The tenant login — a 2-step flow: `login-default` (brand header + "Masuk Sebagai" role
cards) → tap **Tenan** → `login-tenantt` (username/password, Ingat Saya, Lupa Password?,
Masuk) → routes to the tenant Order tab (`menu-order-baru`).

## Required context

- Cached: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/login-default/` and `.../login-tenantt/`
  (reference.png + values.json + tree.txt).
- Prototype: `login-default` --(tap Tenan role)--> `login-tenantt` --(Masuk)--> `menu-order-baru`.
- Reuse shared `AppInput` + `PrimaryButton`. Note: the busboy build already has a
  `LoginScreen` (`lib/features/auth/`) with Tenan/Busboy role cards — reuse/adapt it for the
  tenant flavor (default/expected role = Tenan), or build the tenant login in the tenant
  flavor's feature dir. Report your call.
- Assets: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/assets/` — `login-hero`, `role-tenan`,
  `role-busboy`. Icons via `obra_icons` / existing AppInput.

## Acceptance criteria
- [x] Both `login-default` and `login-tenantt` reproduced from cached references.
- [x] Uses shared `AppInput` + `PrimaryButton`.
- [x] Tenan role card is the primary CTA for this flavor; "Masuk" routes to the tenant Order tab.
- [x] Golden tests for both (self-goldens).

## Covers
- User-visible behavior: Login (2-step)
- Interview Ledger: L1, L5

## Blocked by
2

## Blocking decisions
- Open Question 6 (auth) → UI + navigation only; no real auth.
