---
type: Spec
title: DTW Order — Busboy app (UI from Figma)
---

# DTW Order — Busboy

## Problem

The busboy (courier) side of DTW Order needs its Flutter UI built. A HIFI Figma
design (page 🔴 HIFI Busboy, file `CPWCfPomucIUq4k7hZwtwM`) defines 17 frames covering
login, order management, performance, history, and account flows. This Spec turns that
design into per-screen Work Items that build offline from a local Figma cache.

## Proposed outcome

A Flutter app (busboy flavor) that reproduces the Figma screens pixel-faithfully:
login with role selection, a 4-tab bottom-nav shell (Order / Performa / Riwayat / Akun),
order management with Baru/Antar/Selesai sub-tabs and a success modal, a performance
dashboard, a history section with date tabs and detail views, and an account/profile flow.

## User-visible behavior (from design)

- **Login** (2-step: `login-default` → `login-tenantt`): brand header, "Masuk Sebagai" role
  cards (Tenan / **Busboy**); tapping a role reveals the filled form state (`login-tenantt`)
  with username + password inputs, "Ingat Saya", "Lupa Password?", and the "Masuk" button
  that lands on `menu-order-baru`.
- **Menu Order** (`menu-order-baru` + empty/populated `-baru-2`, `menu-order-antar`,
  `menu-order-selesai`): order list with Baru/Antar/Selesai segmented tabs; add/confirm
  raises a "berhasil ditambahkan" success modal.
- **Performa** (`performa-v1`, `performa-v2`): performance dashboard, two layout variants.
- **Riwayat** (`riwayat-hari-ini`, `riwayat-kemarin`, `riwayat-7-hari`): history with
  date tabs; rows open `detail-riwayat`. Completed orders open `detail-selesai`.
- **Akun** (`akun`) → **Profile Saya** (`profile-saya`).

## Design tokens

Cached at `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`. Key values: success green
`#10A760`/`#0D824B`, neutral text `#2B2F38`/`#667085`, success-tint `#E7F8F0`, card shadow
`0 2 16 rgba(6,51,54,0.1)`; fonts Open Sans (body/headers) + Pacifico ("Order" wordmark)
+ Inter (status bar).

## Constraints & technical decisions

- **Flavor:** busboy (L1).
- **Offline-first build:** implementation and pixel verification read only the local cache
  at `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/` — never live Figma (per `figma-harvest.md`).
- **Cache is complete:** all 17 screens harvested via figma-cli (reference.png @1x +
  values.json + tree.txt). `reference.png` on the 390-wide frames is 398px (≈4px drop-shadow
  bleed per side) — compare at 390 logical px. Shared `assets/` holds 6 raster illustrations
  (@2x/@3x PNG: `login-hero`, `role-tenan`, `role-busboy`, `order-illustration`,
  `order-badge`, `brand-kfc`) and 29 icon SVGs; the back-chevron uses a standard icon.

## Testing strategy

- Widget tests per screen for layout structure and static copy.
- Golden/pixel comparison against each `reference.png` at frame width (1x = logical px).

## Scope boundaries

- **In scope:** UI construction of the 17 busboy frames + routing shell + shared widgets.
- **Out of scope (this Spec):** backend/API wiring, auth, real data, and business logic —
  captured as Open Questions, not invented.

## Open Questions

1. **Auth:** login endpoint, token storage, "Ingat Saya" persistence; is the **Tenan**
   role in scope for this busboy build, or is login role-fixed to Busboy?
2. **Data sources:** APIs for orders (new/deliver/complete), performa metrics, riwayat history.
3. **Order state transitions:** which action moves an order Baru→Antar→Selesai and triggers
   the "berhasil ditambahkan" modal.
4. **Empty / error / loading states** for every list — not present in the design.
5. **List behavior:** pagination and pull-to-refresh.

(Resolved: `login-tenantt` is the second step of the login screen, not a separate Tenan
login — confirmed by the prototype flow.)

See `interview-ledger.md` for decisions (L1–L5). Resolve Open Questions via `/ftk-interview`.
