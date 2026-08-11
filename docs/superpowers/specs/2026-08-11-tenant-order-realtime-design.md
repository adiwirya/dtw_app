# Tenant "Pesanan Masuk" Real-Time Integration Design

Date: 2026-08-11
Status: Approved for implementation planning

## Context

Real busboy password login landed on `feat/busboy-order-app`
(`docs/superpowers/specs/2026-08-09-busboy-real-login-design.md`,
commit `cc0734d`) and has been manually verified against the live Downtown
CMS API. Every other feature in both flavors (busboy: order board/detail,
performa, riwayat, akun; tenant: order board, menu, varian, laporan, admin
toggle) is still backed by hard-coded, synchronous, in-memory mock Riverpod
providers with an explicit `TODO(open-question)` comment pointing at a
non-existent `knowledge/riverpod-patterns.md`.

The user asked to start wiring real data broadly ("koneksiin ke semua
endpoint lain"). That scope was decomposed during brainstorming into
independent sub-projects (one per feature/domain); this spec covers exactly
one: the **tenant** flavor's "pesanan masuk" (incoming orders) board —
`lib/features/tenant/presentation/providers/tenant_order_provider.dart`
(`TenantOrderBoard`) and its screens/widgets. "Tenant" here means the
tenant-branch staff/owner app (kelola menu sendiri, terima/tolak pesanan,
lihat laporan) — an authenticated, bearer-token flavor calling `/v1/...`
routes, **not** the anonymous customer-facing `/v1/storefront/*` flow
described in the `dtw-cms-api-structure` memory (that memory's "tenant =
customer-facing" framing does not match this codebase's actual `tenant*`
routes and is superseded by this spec for this codebase).

**New backend fact learned in this spec's brainstorming** (not previously
in the `dtw-cms-api-structure` memory): the API broadcasts order-created
events in real time over **Laravel Reverb** (Pusher-protocol-compatible),
so this spec integrates a WebSocket client instead of polling.

## Scope

**In scope (this spec):**
- A shared response-envelope/error helper (`ApiException`, generalized from
  `auth_repository.dart`'s ad-hoc `_mapError`), since this is the first
  non-auth repository and the pattern must not be re-copy-pasted per
  feature going forward.
- `TenantOrderRepository`: initial fetch (`GET /v1/orders`), status updates
  (`PATCH /v1/orders/{id}/status` for terima/tolak/siap), and gap-fill
  replay (`GET /v1/broadcast/replay`).
- A `TenantOrder` domain model (plain `@immutable`, matching this
  codebase's existing hand-rolled model convention — no freezed/
  json_serializable, consistent with every other model in the repo).
- Real-time new-order delivery via Laravel Reverb (`laravel_reverb`
  package), replacing the `TenantOrderBoard` mock with an async, stream-fed
  provider.
- Extending `LoginResponse` to carry the tenant branch id needed to pick
  the right private channel — confirmed live (see Data Flow) to live at
  `data.scopes[].tenant_branch_id` for the entry where `type == "branch"`,
  not on `data.user`.
- Lifecycle wiring: connect Reverb on login/session-restore, disconnect on
  logout/401.

**Out of scope (future specs):**
- Every other tenant sub-feature (menu/varian CRUD, laporan, admin
  online/offline toggle) and the entire busboy order feature — separate
  specs per the sub-project decomposition.
- Status-change broadcast sync across multiple staff devices. Per this
  spec's brainstorming, the backend only broadcasts `order.created`; a
  status PATCH from *this* device is reflected optimistically in local
  state, but another device's PATCH is **not** pushed to this device.
  Multi-device status sync is an explicit follow-up, not this spec.
- Exact partial-rejection semantics (which items the customer keeps on a
  partial tolak, whether a fully-rejected order is `CANCELLED` vs. something
  else) — the existing UI mock already flags this as unresolved; this spec
  sends `reason` on the `CANCELLED` PATCH if the API accepts it, verified
  live during implementation, and does not invent new backend behavior.
- Reconnect/backoff tuning beyond what `laravel_reverb` provides out of the
  box.

## Approach

Three approaches were considered for the real-time delivery mechanism
(the repository/model/provider-layering approach is not contested — it
follows the auth feature's precedent):

- **A — Polling** (`Timer.periodic` re-fetching `GET /v1/orders` every
  10-15s). Initially proposed and preferred by the user until it was
  learned the backend already runs Laravel Reverb — rejected once real
  push delivery was confirmed available, since polling would be strictly
  worse (higher latency, wasted requests) with no offsetting simplicity
  benefit big enough to justify ignoring existing infra.
- **B — Manual `web_socket_channel` implementing the Pusher wire protocol
  by hand** (subscribe handshake, ping/pong, private-channel auth,
  reconnect). Rejected — reimplements what an existing package already does
  correctly; more code, more failure surface, no benefit over C for this
  codebase's scale.
- **C — `laravel_reverb` package (chosen)**: purpose-built Dart/Flutter
  client for self-hosted Laravel Reverb (not the official
  `pusher_channels_flutter`, which was the original pick during
  brainstorming but turned out to be cloud-cluster-only — it has no
  host/port override and cannot reach a self-hosted Reverb server at all;
  caught before implementation by checking its README). `laravel_reverb`
  takes an explicit `host`/`port`/`useTls`, an async `authHeaders` callback
  (fits attaching a live bearer token) plus `authEndpoint`, a
  `.private(channel).listen(event, callback)` subscribe API, an
  exponential-backoff auto-reconnect, a `states` stream, and an
  `onReconnected()` hook — the last one is a direct fit for this spec's
  replay-on-reconnect requirement.

## Architecture

```
lib/
  core/
    network/
      dio_provider.dart              (unchanged)
    exceptions.dart                  (existing AuthException; add
                                       ApiException generalizing the same
                                       {message, fieldErrors} shape for
                                       reuse outside auth)
    realtime/
      reverb_config.dart             (new — host/key/TLS constants)
      tenant_realtime_service.dart   (new — Pusher client wrapper,
                                       connect/disconnect/subscribe)
  features/
    auth/
      data/models/login_response.dart (+ branchId field on LoginResponse,
                                          parsed from data.scopes, not
                                          from data.user)
    tenant/
      data/
        models/
          tenant_order.dart          (new — TenantOrder, TenantOrderStatus)
        repositories/
          tenant_order_repository.dart  (new)
      presentation/
        providers/
          tenant_order_provider.dart (rewritten: AsyncNotifier + stream)
        screens/ widgets/            (unchanged — consume AsyncValue)
  bootstrap.dart                     (+ connect realtime service on
                                       session-restore if token present)
```

## Components

- **`ApiException`** (`lib/core/exceptions.dart`): `{message,
  fieldErrors}`, `implements Exception` — the same shape `AuthException`
  already has, extracted so `TenantOrderRepository` (and future
  repositories) reuse one `DioException → ApiException` mapper instead of
  duplicating `_mapError`. `AuthException` becomes a thin alias/subclass so
  the auth feature's existing call sites and tests are untouched.
- **`ReverbConfig`**: constants — host `dtw-cms.gadingemerald.com`, key
  `qvata3lm1xtqpocb9g2i` (a Pusher/Reverb *app key* is a public client-side
  identifier, not a secret — safe to compile into the app, same trust level
  as the API base URL), TLS on, port 443 (assumption: Reverb is
  reverse-proxied on the same host/port as the REST API since it's "the
  same domain" — **verify on first real connection attempt**; if it fails,
  the actual Reverb port needs to be obtained separately).
- **`TenantRealtimeService`**: wraps a `laravel_reverb` `Reverb` client.
  - `Future<void> connect({required String token, required String
    branchId})` — constructs `Reverb(host: ReverbConfig.host, port: 443,
    appKey: ReverbConfig.key, useTls: true, authEndpoint:
    'https://${ReverbConfig.host}/broadcasting/auth', authHeaders: () async
    => {'Authorization': 'Bearer $token'})`, calls `connect()`, then
    `.private('branch.$branchId').listen('order.created', ...)` (the
    channel name the package's `.private()` helper produces is prefixed
    with `private-` automatically per the package's convention — verify
    this against the literal `private-branch.{branchId}` name during
    implementation and pass the raw name instead if the helper's prefix
    doesn't match).
  - `Stream<Map<String, dynamic>> get orderCreated` — the decoded payload
    stream from the `order.created` binding above.
  - `Stream<dynamic> get connectionStates` / `onReconnected` — re-exposes
    the underlying `Reverb.states` stream / `onReconnected()` hook so the
    provider (see below) knows when to run the replay gap-fill.
  - `Future<void> disconnect()` — unsubscribe + disconnect, called on
    logout and on 401.
  - Exposed as `@riverpod TenantRealtimeService tenantRealtimeService(Ref
    ref) => TenantRealtimeService()` (keepAlive, singleton-per-app-session).
- **`TenantOrder`** model: fields confirmed live from `GET /v1/orders?
  branch_id=` (`id`, `order_group_id`, `branch_id`, `receipt_number`,
  `grand_total`, `order_status`, `created_at`, `updated_at`, `items` —
  the last one an empty array on every live sample seen; see the "table
  name / item detail gap" open follow-up below) plus `broadcastEventId`
  (nullable, present only on payloads that arrived via the socket, used
  for replay bookkeeping). `TenantOrderStatus` enum mirrors the backend's
  `order_status` (confirmed live: values are UPPER_SNAKE_CASE strings,
  e.g. `"PENDING"` — `pending`, `preparing`, `ready`, `completed`,
  `partialCompleted`, `cancelled` per the `dtw-cms-api-structure` memory's
  previously-extracted enum) — a **new** enum distinct from the existing
  UI-only `IncomingOrderStatus` (`baru`/`diproses`/`selesai`); a small
  mapper function (`IncomingOrderStatus fromBackend(TenantOrderStatus)`)
  translates for the screens, so the three existing UI tabs don't need to
  change:
  - `pending` → `baru`
  - `preparing` → `diproses`
  - `ready`, `completed` → `selesai`
  - `cancelled` → excluded from the board entirely
  - `partialCompleted` → treated as `selesai` for now (no dedicated UI tab
    exists for it; revisit if the product wants one)

  **Table name / item detail gap (confirmed live, decision made):** the
  live `GET /v1/orders` response has no `table_name` field at all, and
  `items` was an empty array on the one live test order available (`?
  include=items` / `?with=items` / `?expand=items` all made no
  difference); no `GET /v1/orders/{id}` or `/orders/{order_group_id}`
  detail endpoint was found (both 404). Per the user's explicit decision,
  this spec does **not** block on discovering where table/item detail
  actually lives — `IncomingOrderData.tableName` is populated from
  `receiptNumber` (real data, just a repurposed display value) and
  `.items` stays `const []` until the real shape is found in a follow-up.
  `.note` stays `null` (no equivalent field exists). `.time` is formatted
  as `HH:mm` directly from `created_at`'s time portion, with no timezone
  label appended (the API's timestamp timezone was not confirmed, so no
  `WIB` suffix is invented).
- **`TenantOrderRepository`** (constructor-injected `Dio dio`):
  - `Future<List<TenantOrder>> fetchOrders({required String branchId})` →
    `GET /v1/orders?branch_id=<branchId>` — confirmed live: `branch_id` is
    a **required** query param (a request without it 422s with `"The
    branch id field is required."`).
  - `Future<void> updateStatus(String orderId, {required
    TenantOrderStatus status, String? reason})` → `PATCH /v1/orders/{id}
    /status`.
  - `Future<List<TenantOrder>> fetchMissedEvents({required String
    branchId, required int afterId})` → `GET /v1/broadcast/replay?
    after_id=&branch_id=`.
  - All three map `DioException` → `ApiException` via the shared helper.
- **`TenantOrderBoard`** (`@riverpod class ... extends
  _$TenantOrderBoard`, `AsyncNotifier<List<TenantOrder>>`):
  - `build()`: reads the current branch id (from wherever session state
    ends up living post-login, see Data Flow), calls
    `repository.fetchOrders`, then starts listening to
    `tenantRealtimeService.orderCreated` (via `ref.listen` inside `build`,
    torn down automatically on disposal) — each event is parsed into a
    `TenantOrder` and prepended to `state.value` (dedup by `orderId`, since
    a socket event could theoretically race with a fetch that already
    included it). Tracks the highest `broadcastEventId` seen.
  - On stream reconnect (the service exposes a `Stream<bool>
    connectionRestored` or equivalent from the underlying Pusher
    connection-state callback), calls `fetchMissedEvents` with the last
    seen id and merges (dedup) before resuming normal event handling.
  - `accept(orderId)` / `reject(orderId, {reason, rejectedItemNames})` /
    `markReady(orderId)`: call `repository.updateStatus` with the mapped
    target status, then optimistically update local state to the new
    status (matching the current mock's optimistic-transition shape) —
    on `ApiException`, revert the optimistic change and surface the error
    (exact UI surfacing — inline snackbar vs. dialog — left to whichever
    pattern the screen already uses for other errors, not re-litigated
    here since no such pattern exists yet; use a simple `SnackBar` with the
    exception message).

## Data flow

**Branch id resolution:** confirmed live against the real API
(`POST /v1/auth/login` with the tenant test credentials): the response is
`{data: {access_token, user: {id, username}, abilities: [...], scopes:
[{type: "branch", tenant_branch_id: "<uuid>"}]}}` — the branch id is
**not** on `user` at all, it's the `tenant_branch_id` of whichever `scopes`
entry has `type == "branch"`. `LoginResponse.fromJson` parses `data.scopes`
and extracts this (`null` if no branch-typed scope exists — e.g. a
non-tenant/busboy login). The branch id is persisted alongside the auth
token in `SecureLocalStorage` (a second key,
`tenant_branch_id_storage_key`) so it survives app restart without
re-parsing the original login response.

**Login → realtime connect:** After `AuthController.login()` succeeds and
persists the token, it also persists `branchId` and calls
`ref.read(tenantRealtimeServiceProvider).connect(token: ..., branchId:
...)` when the branch id is present (i.e., this is a tenant-flavored
login). Busboy-flavor logins that have no branch id simply skip this —
no behavior change for that flavor.

**Startup (session restore):** `bootstrap()` (already async per the prior
login spec) additionally reads the persisted branch id and, if both token
and branch id are present, connects the realtime service before the first
frame — matching the existing "no visible splash screen" constraint.

**Board display:** `TenantOrderBoard.build()` fetches once, then the
screen maps each `TenantOrder` to an `IncomingOrderData` (via
`fromBackend` for the status + the table-name/items fallback described
above) before its existing sub-tab filtering by `IncomingOrderStatus`
runs unchanged. So the screen's *change* is: consume `AsyncValue`
instead of a plain list, and map `TenantOrder → IncomingOrderData` right
after unwrapping it — the filtering/rendering logic below that point is
untouched (existing `TODO(open-question)` comments already anticipated
this general migration shape, just not the exact mapping step).

**New order arrives (socket):** `order.created` payload → `TenantOrder` →
prepended to state → screen rebuilds → new card appears in the "Baru" tab
with no user action, no polling delay.

**Reconnect:** connection drop (e.g. backgrounding, network blip) →
`laravel_reverb` auto-reconnects with exponential backoff → its
`onReconnected()` hook fires → provider calls
`fetchMissedEvents(afterId: lastSeenId, branchId)` → merge → resume.

**Terima / Tolak / Siap Diambil:** unchanged user-facing flow; underlying
action now issues a real `PATCH` instead of a pure in-memory transition,
with optimistic UI update + rollback-on-error.

**Logout / 401:** `dioProvider`'s existing 401 interceptor and the
`AuthController.logout()` path both additionally call
`tenantRealtimeService.disconnect()`.

## Error handling

| Condition | Handling |
|---|---|
| `fetchOrders` fails (timeout/connection error) | `AsyncError` on the provider — screen shows existing loading/error affordance (whatever `AsyncValue.when` pattern the screen adopts; no bespoke error screen invented here) |
| `updateStatus` fails | Optimistic change rolled back, `SnackBar` with mapped message (422/generic table reused from the auth spec's mapping where applicable) |
| Reverb connection fails to establish (e.g. wrong port/key) | Logged; board still works via the initial `fetchOrders` call, just without real-time updates — degrades to "load once" rather than crashing, since realtime is additive to, not a replacement for, the REST fetch |
| `broadcasting/auth` handshake rejected (token lacks branch scope) | Same degrade-to-REST-only behavior; not treated as a fatal error |

## Testing

- `TenantOrderRepository` unit tests (fetch success/shape, status update
  success, `ApiException` mapping for 422/401/timeout/generic, replay
  fetch) using a fake `Dio` adapter, matching the existing
  `AuthRepository` test's no-mockito convention.
- `TenantOrderBoard` provider tests via `ProviderContainer`, overriding
  `tenantOrderRepositoryProvider` with a fake repository and
  `tenantRealtimeServiceProvider` with a fake service exposing a
  controllable `Stream` (so a socket event, a disconnect, and a reconnect
  can all be simulated without a real socket) — assert: initial load,
  new-order-via-stream appends correctly, dedup on overlapping
  fetch/stream data, reconnect triggers replay-and-merge, accept/reject/
  markReady optimistic-then-confirmed and optimistic-then-rolled-back
  paths.
- Existing widget tests for the tenant order screens/cards are updated
  only as needed to accommodate `AsyncValue` consumption; their assertions
  about card rendering per status stay the same since `IncomingOrderStatus`
  and the screen-level filtering are unchanged.

## Open follow-ups (not blocking this spec)

- **Resolved during this spec's writing** (kept here for record, no longer
  open): branch id lives at `data.scopes[].tenant_branch_id`
  (`type == "branch"`) in the login response, not on `user`; `GET
  /v1/orders` requires a `branch_id` query param; `order_status` values
  are confirmed UPPER_SNAKE_CASE. All verified against the live API with
  real tenant credentials.
- Where table name and item line-item detail actually live (not on the
  `GET /v1/orders` item shape at all — confirmed live, see the "table
  name / item detail gap" note above). Likely lives under `order_group_id`
  via an endpoint not yet found; revisit once either the API docs render
  properly in a browser tool or a backend dev points at the right route.
- Whether `PATCH /v1/orders/{id}/status` actually accepts a `reason` field
  for `CANCELLED`, and the exact body key for the status itself (this spec
  assumes `order_status` for consistency with the list response's field
  name, but this is a mutating call and was deliberately **not** probed
  live against the one real test order without explicit sign-off) — verify
  live at the start of implementation (see plan). If `reason` isn't
  accepted, `reason`/`rejectedItemNames` stay UI-only exactly as they are
  in today's mock (i.e., no regression, just no persistence yet).
- Confirm the real Reverb port/scheme if the "same domain as API, port 443"
  assumption doesn't connect on the first try.
- Multi-device status-change sync (needs the backend to also broadcast an
  `order.updated`/`order.status_updated` event, which it currently does
  not) — separate spec once/if the backend adds it.
- The other tenant sub-features (menu/varian, laporan, admin toggle) and
  the busboy order feature — each gets its own spec, reusing the
  `ApiException` helper introduced here.
