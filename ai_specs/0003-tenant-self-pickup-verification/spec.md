---
type: Spec
title: Tenant Self-Pickup Verification
---

## Problem

The tenant "Terima Pesanan" (accept order) flow treats every order identically, but Figma's design (`🟡 HIFI Tenant` page) and the backend's `POST /v1/orders/{order}/complete-pickup` endpoint (`api-tenant-busboy-guide.md` §3) both distinguish two fulfillment paths: **delivery** (a busboy carries the order to the customer) and **self-pickup** (the customer collects it themselves and gives the tenant a pickup code to confirm). The app currently has no concept of this distinction at all — no field on the order model, no badge on the order card, and no way for a tenant to complete a self-pickup order via its pickup code. The existing "Siap Diambil" action (mark `READY`) is delivery-shaped: once tapped, the order is considered done from the tenant's side and moves straight to "Selesai".

## Proposed Outcome

Every tenant order card shows which fulfillment type it is. A self-pickup order that reaches `READY` stays actionable in "Diproses" with a "Verifikasi Pickup" action instead of disappearing into "Selesai": tapping it opens a code-entry screen where the tenant enters the 6-digit pickup code the customer gives them, in person. A correct code completes the order (`COMPLETED`) and shows a confirmation screen; a wrong code shows an inline error and lets the tenant retry. A delivery order's behavior is unchanged.

## User Stories

1. As a tenant, I see a "Delivery" or "Pickup" badge on every order card (Order Baru, Diproses, Selesai) so I know how each order will be fulfilled.
2. As a tenant, when a self-pickup order is `READY`, I see a "Verifikasi Pickup" button instead of "Siap Diambil", and tapping it opens a code-entry screen.
3. As a tenant, I enter the 6-digit code the customer tells me using an on-screen numpad, and confirm it to complete the order.
4. As a tenant, if I enter the wrong code, I see an error message and can retype without losing my place on the order list.
5. As a tenant, I can back out of the code-entry screen without completing verification (e.g. the customer isn't ready, or I opened it by mistake).
6. As a tenant, a delivery order's flow is unaffected by any of this — `READY` still moves it straight to "Selesai".

## Requirements

1. `OrderFulfillmentType { delivery, selfPickup }` distinguishes the two paths at the model level; every `TenantOrder`/`IncomingOrderData` carries one, parsed from the real `order_group.is_delivery` boolean wherever the payload has an `order_group` to read (`true` → delivery, `false` → self-pickup). [L1], [L2]
2. A fulfillment badge renders on every order card, in every tab (Order Baru, Diproses, Selesai) — "Delivery" (blue) or "Pickup" (amber/yellow), matching Figma's card badge exactly. [L2]
3. Naming avoids a bare "pickup" symbol anywhere it could be confused with the existing `TenantOrderStatus`/busboy-delivery `PENDING_PICKUP` concept — see the Glossary (`GLOSSARY.md`) entries for "Fulfillment Type" and "Verifikasi Pickup". [L2]
4. Status→tab mapping (`incomingOrderStatusFromBackend`) becomes fulfillment-dependent for the `READY` case only:
   - Delivery + `READY` → "Selesai" tab (unchanged).
   - Self-pickup + `READY` → stays in "Diproses" tab; the card's action button is "Verifikasi Pickup" instead of "Siap Diambil".
   - Self-pickup + `COMPLETED` (after a successful pickup-code verification) → "Selesai" tab.
   - `PARTIAL_COMPLETED` → "Selesai" tab regardless of fulfillment type (unchanged).
   - `CANCELLED` → filtered out of every tab regardless of fulfillment type (unchanged). [L3]
5. Accept ("Terima") and reject ("Tolak") behavior is unchanged for self-pickup orders — both fulfillment types use the identical "Order Baru" actions (confirmed identical in Figma).
6. "Verifikasi Pickup" screen:
   - Title "Verifikasi Pickup", subtitle "Masukkan kode pickup yang diberikan oleh customer".
   - 6 digit-display boxes above a custom on-screen numpad (3-column grid: 1-2-3 / 4-5-6 / 7-8-9 / blank-0-backspace). No OS keyboard/`TextField` entry for this screen. [L4]
   - A nav bar with a back action (Figma's frame has none, but the Spec requires one — see [L6]).
   - "Cek Kode" button submits the entered code via `POST /v1/orders/{order}/complete-pickup` (`{pickup_code: "<6 digits>"}`).
   - On success (order now `COMPLETED`): show the confirmation screen — checkmark illustration, "Order Ditemukan!", "Pesanan berhasil diserahkan!", the order's summary card (order id, tenant/brand name, table label + "Pickup", customer name, line items, total), and a "Pesanan Selesai" button that returns to the order board.
   - On a wrong code (422, `"Kode pickup tidak sesuai."`): clear the 6 boxes, show the message inline below them in `AppColors.dangerRed`, keep "Cek Kode" visible; no popup/SnackBar. [L5]
   - On any other failure (network, 5xx, order not `READY`/not self-pickup): surface via the existing `errorMessage`/SnackBar convention used elsewhere in the tenant order flow.
7. The pickup code is never pre-filled, cached, or shown anywhere the tenant reads it from — the tenant only ever receives it verbally from the customer (matches `api-tenant-busboy-guide.md` §3's explicit "never surfaced to tenant reads" constraint).

## Technical Decisions

- `OrderFulfillmentType` parsing mirrors the existing `TenantOrderStatus` pattern (a free function, e.g. `orderFulfillmentTypeFromIsDelivery(bool)`) reading `order_group.is_delivery`. `TenantOrder.fromBroadcastPayload` (the socket/live path) can read it today — its `order_group` map already carries `is_delivery` on the wire. `TenantOrder.fromJson` (the flat `GET /v1/orders` path) has no source for it yet — see Blocking Questions. Until backend adds it, `fromJson` defaults to `OrderFulfillmentType.delivery`: the safer direction to default wrong in, since it only means a real self-pickup order fetched via the initial/REST path behaves like it does today (jumps straight to "Selesai", no verification step) rather than wrongly demanding a pickup code on what might actually be a delivery order. [L1], [L2]
- `IncomingOrderCard`'s existing `IncomingOrderStatus` enum (`baru`/`diproses`/`selesai`) is unchanged; the divergent behavior lives in the mapping function that produces it from `TenantOrderStatus` + `OrderFulfillmentType`, not in a new UI-facing status. [L3]
- The "Verifikasi Pickup" numpad is a new, reusable widget (not the forgot-password flow's OTP-box/`TextField` pattern) — this screen is the only current consumer, but it is written as an independent component in case a later flow needs the same input shape. [L4]
- `complete-pickup` is a new repository method on the existing tenant order repository/provider, following the same optimistic-update-then-rollback-on-failure shape already used by `accept`/`reject`/`markReady` (`_transition`-style) in `tenant_order_provider.dart`.
- Badge colors/icons, extracted directly from the Figma component ("Component 30"): Delivery — text/icon `#2F80ED`, tint background `#EAF2FD`, `Icons.delivery_dining` (no bundled `obra_icons` equivalent of Figma's "hand-platter" glyph). Self-pickup — text/icon `#AD8514`, tint background `#FEF8E8`, `Icons.storefront` (no bundled equivalent of Figma's "concierge-bell" glyph).

## Testing Strategy

- Repository-level: unit tests via the existing `cannedDio`/`routedDio` test seams (success/`COMPLETED` response, 422 wrong-code, 422 wrong-fulfillment-type, network failure) — same convention as every other tenant-order repository method.
- Provider-level: optimistic-update/rollback tests mirroring the existing `markReady`/`reject` test shape.
- Widget-level: the numpad + digit-box screen tested via `WidgetTester` tap sequences (digit entry, backspace, submit-disabled-until-6-digits, wrong-code clears + shows error, back button pops), same convention already used for other digit-entry UI in this app (e.g. `reject_reason_sheet_test.dart`'s interaction-test shape).
- No new Test Seam beyond what's listed — existing fakes (`FakeLocalStorage`, canned/routed Dio adapters) are sufficient.

## Out of Scope

- Changing the backend's actual field/value names for order fulfillment type (mobile-app-only naming decision — see [L2]).
- Any change to the delivery flow's existing "Siap Diambil" behavior.
- A resend/regenerate pickup-code affordance from the tenant side (the code is customer-generated, out of this Spec's scope per `api-tenant-busboy-guide.md`).
- Busboy-side changes — this Spec is tenant-app only.

## Blocking Questions

- `GET /v1/orders`'s confirmed-live item shape (`docs/api-reference.md`) has no `order_group`/`is_delivery` embedded — only `order_group_id` (a bare reference). `is_delivery` is a real, documented field, but it lives on the order-group resource (`POST`/`GET /v1/storefront/orders`) and is only known to reach the tenant app today via the `order.created` broadcast/socket payload's nested `order_group`. **Ask backend to add `is_delivery` (or an embedded `order_group`) to `GET /v1/orders`'s item shape** — without it, any order present on the board from the initial fetch (app open, pull-to-refresh, reconnect gap-fill via `GET /v1/broadcast/replay`) rather than a live socket event has no known fulfillment type. Implementation proceeds now: `fromBroadcastPayload` parses `is_delivery` where the payload has it; `fromJson` defaults to a documented placeholder (see Technical Decisions) until this is confirmed. [L1]

## Notes

- Design source: Figma file "DTW Order", page "🟡 HIFI Tenant" — frames "Tenant Terima Pesanan - Delivery" and "Tenant Terima Pesanan - Pickup", specifically the "Verifikasi Pickup" screen (3 states inspected: empty, filled, success) and the "menu diproses" card states for both fulfillment types.
- Backend contract for the verification call itself (not the order-type field) is already documented and unambiguous: `api-tenant-busboy-guide.md` §3 "Self-Pickup — Tenant Input Kode".
