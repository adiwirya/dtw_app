# Best-Practice Audit — dtw_app

Read-only survey, 2026-09-25. Scope: `lib/core/**`, `lib/features/**`, `test/**`.
Excludes the AsyncValue/ErrorView error-handling pass (already fixed — see
git history). Each item: status `[ ]` open / `[x]` fixed.

## High

- [ ] **Log interceptor leaks response bodies in release builds** —
  `lib/core/network/dio_provider.dart:29`. `LogInterceptor(responseBody: true)`
  has no `kDebugMode`/flavor guard (unlike `bootstrap.dart`, which gates
  Sentry DSN/tracing on `kDebugMode`). Every response body — order details,
  customer data, login payloads — is written to device logs in release builds
  too.

- [ ] **Data model imports a presentation widget** —
  `lib/features/tenant/data/models/tenant_order.dart:2`. Imports
  `lib/features/tenant/presentation/widgets/incoming_order_card.dart` solely
  to reuse the `OrderLineItem` class defined there — a data-layer file
  depending on UI code, backwards from the intended dependency direction.

- [ ] **Duplicate, divergent `OrderLineItem` classes** —
  `lib/features/order/data/models/order_models.dart:31` vs
  `lib/features/tenant/presentation/widgets/incoming_order_card.dart:18`. One
  is an immutable 3-field record (`qty`, `name`, `price`); the other is a
  7-field class with `id`, `subtotal`, `available`, `imageUrl` and different
  defaults. Flagged in a prior scan, still unmerged — easy to reach for the
  wrong one (e.g. missing `id` breaks `rejected_item_ids`).

## Medium

- [ ] **`core/**` still imports feature code** —
  `lib/core/notifications/busboy_fcm_service.dart:3`,
  `new_delivery_alert_controller.dart:9`, `new_order_alert.dart:2-3`,
  `new_order_alert_controller.dart:9-10`,
  `lib/core/printing/receipt_printer_service.dart:4`. `core` imports
  `features/order/...` / `features/tenant/...` types/repositories directly —
  not feature-agnostic. (`core/router/*.dart` importing feature screens is a
  much weaker instance of the same smell, inherent to a router's job.)

- [ ] **Unguarded response envelope casts across tenant repositories** —
  e.g. `product_repository.dart:23,90,102,135,151`,
  `tenant_order_repository.dart:21,75`,
  `modifier_group_repository.dart:23,53,89,117`,
  `tenant_branch_repository.dart:21,37`. Systemic
  `response.data!['data'] as List` / `as Map<String, dynamic>` pattern with no
  null/shape guard. A `{"data": null}` or missing-key response throws a raw
  `TypeError`, which `on DioException catch` does not catch — bypasses
  `mapDioError` entirely, masked only by the generic UI fallback instead of
  surfacing as a real API-contract bug.

- [ ] **Unguarded casts in `TenantOrder.fromJson`** —
  `lib/features/tenant/data/models/tenant_order.dart:82-101`. Unguarded
  `as String`/`as num` on `id`, `order_group_id`, `branch_id`,
  `grand_total`, `order_status`, `created_at`, item `id`/`product_name`/
  `subtotal`/`quantity` with no fallback — any one null/missing throws
  instead of producing a typed parse error.

- [ ] **Copy-paste bug: wrong key deleted on null username** —
  `lib/features/auth/data/repositories/auth_repository.dart:42-51`. Inside
  the `sessionUsername == null` branch, it also runs
  `await _localStorage.delete(sessionRoleStorageKey);` — unrelated to
  username, and wipes a role that was just written a few lines above if the
  username happens to be null on that login response.

- [ ] **401 handler doesn't clear full session storage** —
  `lib/core/network/dio_provider.dart:43-64` vs
  `lib/features/auth/data/repositories/auth_repository.dart:86-92`. The 401
  handler only deletes `authTokenStorageKey` and resets in-memory
  `StateProvider`s; it never deletes `sessionUserIdStorageKey` /
  `sessionUsernameStorageKey` / `sessionNameStorageKey` /
  `sessionRoleStorageKey` / `tenantBranchIdStorageKey` /
  `busboyZoneIdStorageKey` the way explicit `logout()` does — stale identity
  data lingers on disk between an expired-token event and the next login.

- [ ] **Fetch/merge business logic embedded in a widget** —
  `lib/features/tenant/presentation/screens/tambah_menu_screen.dart:121-151`
  (`_loadForEditing`). Calls
  `ref.read(productRepositoryProvider).fetchProduct` /
  `fetchProductModifierGroups` directly from `initState`, does its own
  mapping/state-seeding, and swallows failures with two nested
  `on Object catch` blocks — not unit-testable, bypasses the app's normal
  AsyncNotifier/provider pattern used everywhere else.

- [x] **No test coverage for `tenant_branch_repository.dart`** — 47 lines,
  real dio calls + `mapDioError`, no `tenant_branch_repository_test.dart`.
  Every sibling repository (product, modifier group, tenant order, delivery)
  has one. Fixed: `test/features/tenant/data/repositories/tenant_branch_repository_test.dart`.

  Testing pass (2026-09-25) also added coverage for other real-logic gaps
  found by a follow-up scan, none previously listed here:
  `TenantBranch` model (`fromJson` + `toTenantAdminInfo` date formatting),
  `currentTenantBranchProvider` / `tenantAdminInfoProvider` (including the
  best-effort logo-fetch-failure branch), `analyticsProvider`'s no-Firebase
  branch, `LoginRequest.toJson`, `ProductRepository.fetchCategories`,
  `DailyTarget.progress`, `FirebasePerformanceDioInterceptor` (best-effort
  contract via a real Dio round-trip), `AppShell`'s tab-switch and
  re-tap-pops-to-root behavior, and `ErrorView`'s retry interaction.
  `PluginBusboyFcmService` was investigated and skipped: `FirebaseMessaging`
  has a private constructor and `.instance` requires a real platform-bound
  Firebase app, so — like the realtime/foreground services already excluded
  from this audit — it isn't unit-testable without introducing a
  platform-channel mocking pattern absent from the rest of this suite.

## Low

- [ ] **Catch clause with no `on` type in login** —
  `lib/features/auth/presentation/providers/auth_controller.dart:95`. Bare
  `catch (error)` (flagged by `avoid_catches_without_on_clauses`) — a genuine
  bug (`NoSuchMethodError`, etc.) during login is indistinguishable from an
  expected `ApiException` and shown as the same generic message.

- [ ] **Single-member abstract class, never fixed** —
  `lib/core/printing/receipt_printer_service.dart:164-165`.
  `abstract class ReceiptPrinterService` still has exactly one implementation
  (`SunmiReceiptPrinterService`) and is marked
  `// ignore: one_member_abstracts` instead of being collapsed — pure
  indirection.

- [ ] **Whole-board rebuild on single-item change** —
  `lib/features/order/presentation/screens/order_screen.dart:85`,
  `tenant_order_screen.dart:60`, `riwayat_screen.dart:56`. Screens
  `ref.watch` the whole `AsyncValue<List<T>>` at the top level, so any single
  item change (claim, status update) rebuilds the entire screen body, not
  just the affected item — only worth revisiting if boards grow large.

## Checked, found OK

- No cross-feature (`features/x` ↔ `features/y`) circular imports.
- No hardcoded secrets/leaked API keys in `lib/**` (the Firebase `apiKey` in
  `firebase_options.dart` is the standard public client identifier, not a
  secret).
- `flutter analyze` otherwise clean (style-level infos only).
