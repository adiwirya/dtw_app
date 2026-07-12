---
type: Work Item
title: Tenant flavor shell — entrypoint, routing, bottom nav
parent: ../spec.md
---

## What to build

The tenant product flavor: a `main_tenant.dart` entrypoint + tenant router + a persistent
4-tab bottom navigation (Order / Menu Saya / Laporan / Admin) hosting the main screens.
Routes stub to placeholders for screens not yet built. Establishes flavor separation from
the existing busboy app.

## Required context

- Flow map: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM-tenant/manifest.json` (`flow` = 57 prototype
  edges; `bottomNav` field maps tabs → home routes).
- Tabs → home routes: Order→`menu-order-baru`, Menu Saya→`menu-saya`, Laporan→`laporan`,
  Admin→`admin-offline`. Nav icons in the design: Home, Search, Imagine(chart), Message.
- Existing app: busboy shell is `lib/core/widgets/app_shell.dart` + `lib/core/router/app_router.dart`
  (StatefulShellRoute, tabs Order/Performa/Riwayat/Akun). Entrypoints today: `main_dev.dart`,
  `main_prod.dart` (environment flavors only).
- Reuse the busboy shell's `StatefulShellRoute` + custom bottom-nav pattern; build a tenant
  variant. Reuse theme `lib/core/theme/app_theme.dart`.

## Acceptance criteria
- [x] `main_tenant.dart` entrypoint boots the tenant experience.
- [x] Tenant router with a 4-tab bottom-nav shell (Order/Menu Saya/Laporan/Admin); active state uses success green.
- [x] Named routes for all 34 tenant frames; unbuilt routes stub to placeholders.
- [x] Login sits outside the shell; post-login lands on the Order tab (`menu-order-baru`).
- [x] Widget test asserts tab switching changes the hosted screen.

## Covers
- Requirements: tenant flavor shell + navigation
- Interview Ledger: L1, L3, L5

## Blocked by
None - ready to start

## Blocking decisions
- Open Question 1: refactor the existing busboy app into a `busboy` flavor vs. add tenant as
  a parallel entrypoint leaving busboy default. Decide + document; do not break the busboy
  app or its tests.
