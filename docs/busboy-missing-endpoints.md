# Busboy App — Endpoint Gaps vs UI

What the busboy flavor's UI (Figma-derived screens under
`ai_specs/0001-busboy-order-app/`) needs from the backend that
`docs/api-reference.md` has no endpoint for today. Each gap lists the screen
that needs it, what the app currently shows instead, and the code seam to
wire up once the endpoint exists. Not a request spec — a map of where the app
is showing a placeholder (`-`) or fabricated value because there is nowhere
real to fetch it from.

Cross-checked against `api.json` as of 2026-09-04. Endpoints that already
exist but are simply unused client-side (e.g. `POST /v1/busboy/fcm-token` —
no `firebase_messaging` wiring yet) are **not** listed here; this is only
endpoints that don't exist.

## Order tab (`menu-order-baru`)

### 1. On-time rate / customer rating summary stats
- **Where:** header stats card, "Ketepatan Waktu" and "Rating Pelanggan".
- **Now:** both hardcoded to `-`. "Pesanan Selesai" (the third stat) is real —
  computed client-side from today's `DELIVERED` deliveries already on the
  board, no new endpoint needed for that one.
- **Needs:** an endpoint (or fields on an existing busboy summary/profile
  endpoint) returning an on-time-delivery percentage and an average customer
  rating, scoped to the logged-in busboy.
- **Wire up at:** `orderHeaderStats` in
  `lib/features/order/presentation/providers/order_provider.dart`.

### 2. Call customer
- **Where:** order detail screen (`menu-order-baru-2`), phone button on the
  "Pelanggan" row.
- **Now:** stubbed tap handler, no-op — `Delivery`/`DeliveryOrder` carry no
  customer phone number at all.
- **Needs:** a `customer_phone` (or similar) field on
  `GET /v1/busboy/deliveries` — there's currently no phone number anywhere in
  that response to call.
- **Wire up at:** `OrderDetailScreen._take`'s `onCall` callback in
  `lib/features/order/presentation/screens/order_detail_screen.dart`.

### 3. Realtime claim/complete broadcast
- **Where:** all three Order sub-tabs (Baru/Antar/Selesai) across every
  busboy device sharing a zone.
- **Now:** only `delivery.created` is broadcast on `private-zone.<zoneId>`.
  When busboy A claims or completes a delivery, busboy B's device has no way
  to know until it manually pull-to-refreshes or reopens the screen — a
  stale card can sit in the wrong sub-tab, and a claim attempt on an
  already-taken delivery only surfaces as a 409 after the tap.
- **Needs:** `delivery.claimed` / `delivery.completed` (or a single
  `delivery.updated` carrying the new status) broadcast on the same
  `private-zone.<zoneId>` channel, mirroring `delivery.created`'s shape.
- **Wire up at:** add a listener next to `deliveryCreated` in
  `lib/core/realtime/busboy_realtime_service.dart`, consumed by
  `OrderBoardNotifier` in `order_provider.dart`.

## Performa tab (`performa-v1`, `performa-v2`)

Both frames are **100% fabricated mock data** — there is no busboy
performance/metrics endpoint at all yet, so nothing here is even partially
wired to a real source.

- **`performa-v1`:** overall performance %, average delivery time + delta,
  on-time %, customer rating, an hourly delivery-volume chart ("Performa per
  Jam"), and a fastest/average/slowest delivery-time breakdown.
- **`performa-v2`:** completed-order count + delta, average delivery time,
  SLA on-time %, customer rating, a daily target + progress bar, a 7-day
  weekly bar chart, and a text "Insight Hari ini" callout.
- **Needs:** a busboy performance-dashboard endpoint (e.g.
  `GET /v1/busboy/performance?range=...`) returning at least: completed-order
  counts (today/daily-target/weekly series), delivery-time stats
  (avg/fastest/slowest + trend deltas), on-time/SLA rate, customer rating, and
  an hourly delivery-volume series. Whether "Insight Hari ini" is
  server-generated text or a client-side rule over the other numbers is an
  open product question, not just an API gap.
- **Wire up at:** `performaV1DataProvider` / `performaV2DataProvider` in
  `lib/features/performa/presentation/providers/performa_provider.dart` —
  currently synchronous providers returning `const` data; swap for an async
  repository fetch per the file's own `TODO(open-question)`.

## Riwayat tab (`riwayat-hari-ini`, `-kemarin`, `-7-hari`)

Already real — backed by
`GET /v1/busboy/deliveries?status=DELIVERED` — but with one scaling gap:

- **No date-range/pagination query params.** The endpoint returns every
  `DELIVERED` delivery unbounded; the three date tabs (Hari Ini / Kemarin /
  7 Hari Terakhir) are bucketed client-side off that single unfiltered list.
  Fine at current volume, but will need a real `date_from`/`date_to` (or
  `range=`) + pagination param once history grows.
- **Wire up at:** `RiwayatBoard.build` in
  `lib/features/riwayat/presentation/providers/riwayat_provider.dart`.

## Akun tab (`akun`) and Profil Saya (`profile-saya`)

There is no busboy profile endpoint at all. `name` (the greeting) is the
only field with a real source — the session's login username
(`sessionUsernameProvider`). Everything else below is `-`.

### 4. Busboy profile — read
- **Where:** Akun home (Busboy ID, join date, 3 performance stats) and
  Profil Saya (Busboy ID, full name, phone, email, outlet, shift).
- **Now:** every field except the greeting name is `-`.
- **Needs:** a `GET /v1/busboy/profile` (or `GET /v1/users/me`-style) endpoint
  returning: busboy id, full name, phone, email, assigned outlet/branch,
  shift, join date, and the same performance-stat fields as the Performa
  endpoint above (completed-task count, avg delivery time, rating) — Akun's
  stats box and Performa's metrics look like the same underlying numbers
  presented twice, so these may end up being one data source.
- **Wire up at:** `akunAccountProvider` in
  `lib/features/akun/presentation/providers/akun_provider.dart` and
  `busboyProfileProvider` in
  `lib/features/akun/presentation/providers/profile_provider.dart`.

### 5. Busboy profile — update
- **Where:** Profil Saya's "Simpan" button (editable: full name, phone,
  email) and the avatar upload affordance.
- **Now:** "Simpan" shows a snackbar ("Perubahan disimpan (mock)") and
  persists nothing; the avatar tap has no handler.
- **Needs:** a `PATCH`/`PUT /v1/busboy/profile` mutation endpoint, and an
  avatar upload endpoint (mirrors `POST /v1/brands/{id}/logo` on the tenant
  side).
- **Wire up at:** `ProfileSayaScreen._onSave` in
  `lib/features/akun/presentation/screens/profile_saya_screen.dart`.

### 6. Account menu actions
- **Where:** Akun's menu rows — "Ubah Kata Sandi", "Bahasa", "Bantuan & FAQ",
  "Kebijakan Privasi".
- **Now:** tap is a no-op stub (`AkunScreen._onMenuTap`'s
  `TODO(open-question)`); no destination route exists for any of the four.
- **Needs:** a change-password mutation is the only one of the four that's
  clearly a backend gap. "Bahasa" (device-local language toggle),
  "Bantuan & FAQ", and "Kebijakan Privasi" (static content) may not need a
  backend endpoint at all — flag to product/design before assuming these need
  API work.
- **Wire up at:** `AkunScreen._onMenuTap` in
  `lib/features/akun/presentation/screens/akun_screen.dart`.

## Login (`login-default` → `login-tenantt`)

### 7. Forgot password
- **Where:** "Lupa Password?" link on the filled login form.
- **Now:** stubbed, no destination (`TODO(open-question)` in
  `login_screen.dart`).
- **Needs:** a password-reset flow endpoint (request + confirm, typically
  email or SMS OTP-based).
- **Wire up at:** the `'Lupa Password ?'` `GestureDetector`/`InkWell` in
  `lib/features/auth/presentation/screens/login_screen.dart`.

## Summary table

| # | Screen | Missing endpoint | Priority |
|---|--------|-------------------|----------|
| 1 | Order home | On-time rate + rating stats | Low — cosmetic, 1 of 3 stats already real |
| 2 | Order detail | Customer phone field | Low — feature not confirmed in scope |
| 3 | Order (all tabs) | `delivery.claimed`/`delivery.completed` broadcast | **High** — causes stale/racy multi-busboy state |
| — | Performa v1 + v2 | Full performance-dashboard endpoint | **High** — entire tab is fake data |
| — | Riwayat | Date-range/pagination params | Low — works today, scaling concern only |
| 4 | Akun + Profil Saya | Profile read endpoint | **High** — entire identity/stats block is fake |
| 5 | Profil Saya | Profile update + avatar upload | Medium — "Simpan" is currently a lie to the user |
| 6 | Akun | Change-password mutation | Medium |
| 7 | Login | Forgot-password flow | Medium |
