---
type: Work Item
title: Shared — auth input field + primary button
parent: ../spec.md
---

## What to build

Reusable form widgets used across the login screens (and reused app-wide): a text
`Input` field with leading icon (and optional trailing icon), and the primary pill button.

## Required context

- Cached reference: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/login-default/reference.png`.
- Values: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/login-default/values.json`.
- Input: height 40, radius 12, border `#D0D3D9`, placeholder `#667085` Open Sans 14,
  leading icon 20px (user-round / lock-keyhole), trailing icon (eye) for password.
- Button: bg `#10A760`, radius 100, height 40, full-width, label Open Sans SemiBold 16 white.
- Tokens: `.ftk/figma/CPWCfPomucIUq4k7hZwtwM/tokens.json`.

## Acceptance criteria
- [x] `AppInput` widget: leading icon, placeholder, optional obscureText + trailing eye toggle.
- [x] `PrimaryButton` widget: full-width pill, success-green, tap callback.
- [x] Widget tests for both against the cached values.

## Covers
- Requirements: shared components; Login user-visible behavior
- Interview Ledger: L3

## Blocked by
None - ready to start
