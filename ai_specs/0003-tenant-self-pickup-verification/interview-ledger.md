---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: What API field on `GET /v1/orders` distinguishes a self-pickup order from a delivery order?

Answer: A real, confirmed field exists — `is_delivery` (boolean) — but it lives on the **order group** resource (`POST`/`GET /v1/storefront/orders`), not on the flat `order` item `GET /v1/orders` returns. The existing `order.created` broadcast/socket payload already nests `order_group: {..., is_delivery: ..., ...}` alongside the flat order (confirmed in `test/features/tenant/data/models/tenant_order_test.dart`'s existing broadcast-payload fixture) — so a live-arriving order CAN carry it — but `GET /v1/orders`'s own confirmed-live item shape (`docs/api-reference.md`) has no `order_group`/`is_delivery` embedded at all, so an order fetched by the initial board load (not live-broadcast) has no way to know its fulfillment type today.

Recommended Answer: Proceed on the assumption that `is_delivery` is the real field, parse it wherever it's already reachable (the broadcast/socket payload), and record the `GET /v1/orders` gap explicitly as a Blocking Question for backend rather than blocking all implementation on it.

Answer: Agreed — proceed, gap goes in the Spec's Blocking Questions.

Decision: `OrderFulfillmentType` parses from `order_group.is_delivery` (`true` → delivery, `false` → self-pickup) wherever the payload has an `order_group` to read (the broadcast/socket path, `TenantOrder.fromBroadcastPayload`). `TenantOrder.fromJson` (the flat `GET /v1/orders` shape) has no source for this field today — see Blocking Questions in the Spec for what backend needs to add.

Reason: Confirmed via `docs/api-reference.md`'s documented `POST /v1/storefront/orders`/`GET /v1/storefront/orders/{groupId}` shape (`is_delivery` among the listed response fields) and the pre-existing (already-committed, not written for this feature) broadcast-payload test fixture that already includes `order_group.is_delivery` — this is real API surface, not a guess, but it does not yet reach every path this feature needs it on.

### L2

Status: current

Question: The codebase already uses `PENDING_PICKUP` as a busboy-delivery lifecycle status (a busboy waiting to collect an order from the tenant to deliver it) — an unrelated concept from "the customer collects their own order." What should the new concept be called in code, and does this rename touch the backend?

Recommended Answer:
- Use `OrderFulfillmentType { delivery, selfPickup }` (not a bare `pickup` enum/field name) for the tenant-order fulfillment concept.
- UI labels stay the Indonesian text from Figma ("Delivery" / "Pickup") — only the Dart-level naming avoids the word "pickup" alone.
- This is a mobile-app-only naming/translation layer, exactly like `TenantOrderStatus`'s wire-to-enum mapping (`tenantOrderStatusFromWire`/`ToWire`) — it does not ask the backend to rename anything; the backend's own field/values stay whatever L1 resolves them to be.

Answer: Agreed — mobile-app-only naming is fine.

Decision: Introduce `OrderFulfillmentType { delivery, selfPickup }` (model field `fulfillmentType`), a `FulfillmentBadge` widget (not `PickupBadge`), and an `onVerifyPickup` action name (not a bare `onPickup`) — distinct from the existing `onPickupReady` (delivery's "Siap Diambil"). Purely a client-side/Dart naming decision; the wire contract is whatever L1 resolves to.

Negative Requirements:
- Never name a new symbol with a bare "pickup" that could be confused with `TenantOrderStatus`/busboy-delivery's `PENDING_PICKUP`.

### L3

Status: current

Question: Confirm the status→tab mapping change: today `READY` (any order) maps straight to the "Selesai" tab. Should a self-pickup order's `READY` state stay in "Diproses" instead, showing "Verifikasi Pickup" in place of "Siap Diambil", only moving to "Selesai" once `COMPLETED`? Do `PARTIAL_COMPLETED` and `CANCELLED` change?

Recommended Answer:
- Delivery: `READY` → "Selesai" tab, unchanged (busboy takes over from here).
- Self-pickup: `READY` → stays in "Diproses" tab, action button becomes "Verifikasi Pickup"; only `COMPLETED` (after a successful `complete-pickup` call) moves it to "Selesai".
- `PARTIAL_COMPLETED` and `CANCELLED` are unaffected by fulfillment type: `PARTIAL_COMPLETED` → "Selesai" same as today; `CANCELLED` stays filtered out of every tab (per `TenantOrder.fromJson`'s upstream board filter), same as today.

Answer: Confirmed as recommended — verified `PARTIAL_COMPLETED`/`CANCELLED` behavior against the current code (`incomingOrderStatusFromBackend`, `tenant_order_provider.dart`'s `cancelled` board filter) before confirming.

Decision: `incomingOrderStatusFromBackend`'s mapping becomes fulfillment-type-dependent for the `ready` case only; every other status mapping is unchanged.

### L4

Status: current

Question: Figma's "Verifikasi Pickup" screen uses a custom on-screen numpad (a 1–9/0/backspace grid) to enter the 6-digit pickup code, unlike the existing forgot-password OTP flow's 6 invisible `TextField` boxes + OS keyboard. Reuse the existing OTP-box pattern, or build a new custom numpad matching Figma exactly?

Recommended Answer: Reuse the existing OTP-box + OS-keyboard pattern — same functional behavior, less new code, visual style can still match Figma's box styling.

Answer: Prefer the custom numpad, matching Figma exactly.

Decision: Build a new custom on-screen numpad widget (3-column grid: 1-2-3 / 4-5-6 / 7-8-9 / blank-0-backspace) driving 6 digit-display boxes above it — no OS keyboard/`TextField` involved for this screen.

### L5

Status: current

Question: Figma shows no explicit "wrong code" state for Verifikasi Pickup (only empty, filled, and the post-success "Order Ditemukan" screen). The API returns 422 `"Kode pickup tidak sesuai."` on a wrong code. What should the error state look like?

Recommended Answer: An inline red error message below the 6 digit boxes (`AppColors.dangerRed`, same convention as other validation messages in the app), the boxes auto-clear so the tenant can retype, "Cek Kode" stays in place. No popup/SnackBar, so the tenant doesn't lose screen context.

Answer: Agreed, as recommended.

Decision: Wrong-code (422) response clears the 6 digit boxes and shows an inline red error message below them; no dialog/SnackBar.

### L6

Status: current

Question: The Verifikasi Pickup screen has no back/close affordance anywhere in the Figma frame (confirmed via the Figma node tree) — should the built screen match that (no way out except completing verification), or add a way back?

Recommended Answer: Add a back affordance (matching every other screen's nav-bar-with-back convention, e.g. `ForgotPasswordNavBar`/the reject flow's `_RejectNavBar`) — a tenant who opened this by mistake, or whose customer left, must be able to return to the order list without being stuck.

Answer: Agreed, add a back button.

Decision: The Verifikasi Pickup screen gets a nav bar with a back action, despite Figma's frame showing none.
