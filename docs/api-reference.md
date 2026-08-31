# Downtown CMS API Reference

Reference for the backend `dtw_app` (busboy + tenant flavors) talks to.
Generated from the live OpenAPI spec at `https://dtw-cms.gadingemerald.com/docs/api/`
(embedded as JS in that page, not exposed as a static `/docs/api-json` file —
see "Re-extracting this doc" at the bottom) and cross-checked against real
API responses. Regenerate this file whenever the backend spec changes
meaningfully; it is a snapshot, not a live source.

## Basics

- **Base URL**: `https://dtw-cms.gadingemerald.com/api`
- **Auth**: bearer token (`Authorization: Bearer <token>`) from
  `POST /v1/auth/login`. `method: "password"` (username/password, CMS/staff,
  8h session) or `method: "card"` (`card_uid`, NFC tap-login on cashier
  devices, 30d session).
- **Envelope**: every response is `{ meta: {success, message, code, trace_id}, data }`.
  Validation errors (422) use `{ meta, errors: {field: [msgs]} }`; 401 uses
  `{ meta, errors: null }`. List endpoints add `meta.pagination_meta:
  {current_page, page_size, total_items, total_pages}`.
- **Pagination**: only `per_page` / `all` query params are documented — no
  `page` param despite `pagination_meta` implying page-based paging. Test
  `?page=N` empirically before relying on it.
- **Flavor split**: every `/v1/storefront/*` route (scan, products, modifiers,
  orders) plus `POST /v1/webhooks/doku/payment` and `GET /ping` need **no**
  bearer token — these are what the customer-facing storefront calls.
  Everything else needs a bearer token — what the busboy/tenant staff app
  calls after login.
- **Domain hierarchy**: `Owner → Brand → TenantBranch → Product/Table/Zone`,
  `Area → Zone → Table`.

## Confirmed gaps and live findings

These are things the static spec gets wrong, leaves untyped, or that only
showed up by actually calling the API — check here before assuming a field
exists or guessing at a shape.

- **`GET /v1/tenant-branches/{id}` has no booth/location, rating, contact, or
  operating-hours fields.** The Admin/profile screen in the app hides those
  UI slots rather than fabricate values (see `TenantAdminInfo` in the app).
- **Branch photo vs brand logo are two different fields on two different
  resources — do not conflate them:**
  - `tenant-branches.banner_url` — a wide promotional banner. Upload via
    `POST /v1/tenant-branches/{id}/banner`, spec requires **min. 1280×720px**.
  - `brands.logo_url` — the round brand logo. Upload via
    `POST /v1/brands/{id}/logo`.
  - Both were `null` for every branch/brand checked live as of 2026-08-13
    (fresh seed data, nothing uploaded yet) — a null here means "nobody has
    uploaded one," not a broken field.
- **List endpoint item shapes are untyped in the spec** (`"data": {"type":
  "array", "items": {}}` — no `$ref`, nothing). Infer the item shape from the
  matching single-resource `GET /{id}` response documented below, or confirm
  live. `GET /v1/orders` in particular has two candidate shapes in different
  parts of the spec (order-group-level vs per-branch-order-level) — confirmed
  live, the per-branch-order shape is what it actually returns (see Order
  section below).
- **`GET /v1/orders` items are always an empty array** in live responses —
  no confirmed source for order line items yet from this endpoint.
- **`Role` schema is a bare `{type: object}`** — no fields documented at all.
- **Realtime (Reverb/WebSocket) connectivity is unresolved as of 2026-08-13.**
  Broadcasting is same-domain (`dtw-cms.gadingemerald.com`) per the backend
  team, Pusher-protocol app key `qvata3lm1xtqpocb9g2i`. Neither obvious port
  worked from a real device: port 443 responds but with a plain 404 (wrong
  route, not a WebSocket upgrade); port 8080 times out (unreachable
  externally). `GET /v1/broadcast/replay?branch_id=&after_id=` is confirmed
  as the gap-fill/reconnect endpoint for missed events regardless of which
  port ends up being right.
- **Login response shape (`POST /v1/auth/login`, confirmed live)**:
  ```json
  {
    "meta": {"success": true, "message": "Success", "code": 200, "trace_id": "..."},
    "data": {
      "access_token": "15|...",
      "user": {"id": "uuid", "username": "..."},
      "abilities": ["modifier-groups:view", "tenant-branches:view", "..."],
      "scopes": [{"type": "branch", "tenant_branch_id": "uuid"}]
    }
  }
  ```
  A branch-scoped session (tenant staff) has a `scopes` entry with
  `type: "branch"` and `tenant_branch_id` — that id is what every
  branch-scoped call (`GET /v1/tenant-branches/{id}`, `GET /v1/orders?branch_id=`,
  the Reverb `private('branch.<id>')` channel) uses. A busboy/non-branch
  session has no such scope.
- **`GET /v1/tenant-branches/{id}` shape (confirmed live)**:
  ```json
  {
    "id": "uuid", "brand_id": "uuid", "brand_name": "Janji Jiwa",
    "owner_name": "PT Luna Boga Narayan", "area_id": "uuid", "area_name": "Downtown",
    "branch_name": "Janji Jiwa", "kd_unit": "MKOJ", "kd_lokasi": "SMLB",
    "banner_url": null, "is_active": true,
    "settlement_account": {"id": "uuid", "bank_account_settlement_id": "...", "bank_code": "014", "account_number": "...", "account_holder_name": "..."},
    "created_at": "2026-08-07 09:16:37", "updated_at": "2026-08-07 09:16:37"
  }
  ```
- **`GET /v1/orders` item shape (confirmed live, per-branch-order-level)**:
  ```json
  {
    "id": "uuid", "order_group_id": "uuid", "branch_id": "uuid",
    "receipt_number": "RCP-20260807-IOOXVF", "grand_total": 21000,
    "order_status": "PENDING", "created_at": "2026-08-07 09:24:08",
    "updated_at": "2026-08-07 09:24:08", "items": [],
    "broadcast_event_id": 12
  }
  ```
  `order_status` is an UPPER_SNAKE_CASE enum:
  `PENDING | PREPARING | READY | COMPLETED | PARTIAL_COMPLETED | CANCELLED`.

## Endpoints by tag

Field lists are the resource's own properties (one level deep) from the
response `data` (or `data[]]` item). `?` after a tag name means the OpenAPI
`tags` array used a name Stoplight groups loosely — check the path itself
when in doubt.

### Tenant Branches

- `GET /v1/tenant-branches/banks` — supported Indonesian bank codes for settlement.
- `GET /v1/tenant-branches` — list. Item shape: same as `GET /{id}` below.
- `POST /v1/tenant-branches` — create. Request: `brand_id`, `area_id`, `branch_name`, `bank_code`, `account_number`, `account_holder_name`, `kd_unit`, `kd_lokasi`, `outlet_category_ids`.
- `GET /v1/tenant-branches/{id}` — get. Response: `id`, `brand_id`, `brand_name`, `owner_name`, `area_id`, `area_name`, `branch_name`, `kd_unit`, `kd_lokasi`, `banner_url`, `is_active`, `settlement_account`, `created_at`, `updated_at`.
- `PUT /v1/tenant-branches/{id}` — update. Request: `branch_name`, `is_active`, `outlet_category_ids`.
- `POST /v1/tenant-branches/{id}/banner` — upload branch banner (multipart `banner`; JPEG/PNG/WebP, min 1280×720px, max 5MB). Response: same shape as GET.
- `DELETE /v1/tenant-branches/{id}/banner` — remove the banner.
- `GET /v1/tenant-branches/{id}/settlement-accounts` — list settlement bank accounts.
- `POST /v1/tenant-branches/{id}/settlement-accounts` — add/replace. Request: `bank_code`, `account_number`, `account_holder_name`.

### Products

- `GET /v1/products` — list. Item shape: same as `GET /{id}` below.
- `POST /v1/products` — create. Request: `brand_id`, `category_id`, `sku`, `name`, `description`, `tags`, `price`. `price` is **tax-inclusive** (what the customer pays); the backend splits it into `dpp_price` + `pb1_price` and echoes the same figure back as `total_price`.
- `GET /v1/products/{id}` — get. Response: `id`, `brand_id`, `brand_name`, `category_id`, `category_name`, `sku`, `name`, `description`, `tags`, `dpp_price`, `pb1_percentage`, `pb1_price`, `total_price`, `image_url`, `is_active`, `created_at`, `updated_at`.
- `PUT /v1/products/{id}` — update. Request: `category_id`, `sku`, `name`, `description`, `tags`, `price` (tax-inclusive, as on create), `is_active`.
- `POST /v1/products/{id}/image` — upload product image (multipart `image`). Response: same shape as GET.

### Product Categories

- `GET /v1/product-categories` — list. Item shape: same as `GET /{id}` below.
- `POST /v1/product-categories` — create. Request: `brand_id`, `parent_category_id`, `name`, `sequence_order`.
- `GET /v1/product-categories/{id}` — get. Response: `id`, `brand_id`, `brand_name`, `parent_category_id`, `parent_category_name`, `name`, `sequence_order`, `is_active`, `created_at`, `updated_at`.
- `PUT /v1/product-categories/{id}` — update. Request: `parent_category_id`, `name`, `sequence_order`, `is_active`.
- `DELETE /v1/product-categories/{id}` — delete.
- `POST /v1/product-categories/reorder` — reorder. Request: `parent_category_id`, `ids`.

### Modifier Groups

- `GET /v1/modifier-groups` — list. Item shape: same as `GET /{id}` below.
- `POST /v1/modifier-groups` — create. Request: `brand_id`, `name`, `description`, `min_selections`, `max_selections`.
- `GET /v1/modifier-groups/{id}` — get, with options. Response: `id`, `brand_id`, `brand_name`, `name`, `description`, `is_required`, `min_selections`, `max_selections`, `sequence_order`, `is_active`, `option_count`, `created_at`, `updated_at`, `options`.
- `PUT /v1/modifier-groups/{id}` — update. Request: `name`, `description`, `min_selections`, `max_selections`, `is_active`.
- `POST /v1/modifier-groups/reorder` — reorder within a brand. Request: `brand_id`, `ids`.
- `POST /v1/modifier-groups/{groupId}/options` — add an option. Request: `name`, `price` (tax-inclusive, as on products). Response: `id`, `modifier_group_id`, `name`, `dpp_price`, `pb1_percentage`, `pb1_price`, `total_price`, `sequence_order`, `created_at`, `updated_at`.
- `PUT /v1/modifier-groups/{groupId}/options/{optionId}` — update an option. Request: `name`, `price` (tax-inclusive).
- `POST /v1/modifier-groups/{groupId}/options/reorder` — reorder options. Request: `ids`.

### Menu Availability

Per-branch overrides of product/modifier-option availability (not the same
as a product/option's own `is_active`), documented in the OpenAPI spec
(`api.json`) but **not live** — confirmed 2026-08-31 the product-availability
route 404s on the real server. The tenant Menu Saya toggle uses
`is_active` via `PUT /v1/products/{id}` instead (see Products above).

- `GET /v1/tenant-branches/{branch}/product-availability` — list. Spec-only, not live.
- `PATCH /v1/tenant-branches/{branch}/product-availability/{product}` — toggle. Request: `is_available`. Spec-only, not live.
- `GET /v1/tenant-branches/{branch}/modifier-option-availability` — list. Not confirmed live.
- `PATCH /v1/tenant-branches/{branch}/modifier-option-availability/{option}` — toggle. Request: `is_available`. Not confirmed live.

### Auth

- `POST /v1/auth/login` — see the confirmed shape above. Request: `method` (`"password"` | `"card"`), `username`, `password`, `card_uid`.
- `POST /v1/auth/logout` — revoke the current session token.

### Brand

- `GET /v1/brands` — list. Item shape: same as `GET /{id}` below.
- `POST /v1/brands` — create. Request: `owner_id`, `name`.
- `GET /v1/brands/{id}` — get. Response: `id`, `owner_id`, `owner_name`, `owner_kd_unit`, `name`, `logo_url`, `is_active`, `created_at`, `updated_at`.
- `PUT /v1/brands/{id}` — update. Request: `name`, `is_active`.
- `POST /v1/brands/{id}/logo` — upload the round brand logo (multipart `logo`). Response: same shape as GET.
- `DELETE /v1/brands/{id}/logo` — remove the logo.

### Owner

- `GET /v1/owners` — list. Item shape: same as `GET /{id}` below.
- `POST /v1/owners` — create. Request: `company_name`, `kd_unit`.
- `GET /v1/owners/{id}` — get. Response: `id`, `company_name`, `kd_unit`, `is_active`, `created_at`, `updated_at`.
- `PUT /v1/owners/{id}` — update. Request: `company_name`, `kd_unit`, `is_active`.

### Area / Zone / Table

- `GET /v1/areas` — list. Item: same as `GET /{id}`.
- `POST /v1/areas` — create. Request: `name`, `scopes`. Response: `id`, `name`, `scopes`, `is_active`, `created_at`, `updated_at`.
- `GET /v1/areas/{id}` / `PUT /v1/areas/{id}` (request: `name`, `is_active`, `scopes`) / `DELETE /v1/areas/{id}`.
- `GET /v1/zones` — list. Item: same as `GET /{id}`.
- `POST /v1/zones` — create. Request: `area_id`, `name`, `description`, `is_active`. Response: `id`, `area_id`, `area_name`, `name`, `description`, `is_active`, `table_count`, `active_table_count`, `created_at`, `updated_at`.
- `GET /v1/zones/{id}` / `PUT /v1/zones/{id}` (request: `name`, `description`, `is_active`) / `DELETE /v1/zones/{id}`.
- `GET /v1/tables` — list. Item: same as `GET /{id}`.
- `POST /v1/tables` — create. Request: `zone_id`, `code`. Response: `id`, `zone_id`, `zone_name`, `code`, `qr_code_path`, `is_active`, `created_at`, `updated_at`.
- `GET /v1/tables/{id}` / `PUT /v1/tables/{id}` (request: `code`, `is_active`) / `DELETE /v1/tables/{id}`.

### BranchOutletCategory / OutletCategory

- `GET /v1/branches/{branchId}/outlet-categories` — list a branch's outlet categories.
- `POST /v1/branches/{branchId}/outlet-categories/sync` — replace the set. Request: `outlet_category_ids`.
- `GET /v1/outlet-categories` — list. Item: same as `GET /{id}`.
- `POST /v1/outlet-categories` — create. Request: `name`. Response: `id`, `name`, `sequence_order`, `is_active`, `created_at`, `updated_at`.
- `GET /v1/outlet-categories/{id}` / `PUT /v1/outlet-categories/{id}` (request: `name`, `is_active`).
- `POST /v1/outlet-categories/reorder` — reorder. Request: `ids`.

### Device

- `GET /v1/devices` — list. Item: same as `GET /{id}`.
- `POST /v1/devices` — create. Request: `tenant_branch_id`, `code`, `name`, `ip_address`, `description`. Response: `id`, `tenant_branch_id`, `kd_unit`, `kd_lokasi`, `code`, `name`, `ip_address`, `description`, `active`, `created_by`, `updated_by`, `created_at`, `updated_at`.
- `GET /v1/devices/{id}` / `PUT /v1/devices/{id}` (request: `tenant_branch_id`, `code`, `name`, `ip_address`, `description`, `active`).
- `PATCH /v1/devices/{deviceId}/fcm-token` — set the push token. Request: `fcm_token`.

### Order

- `POST /v1/storefront/orders` — **storefront, no auth.** Create a multi-branch order group. Request: `orders`, `grand_total`, `table_id`, `is_delivery`, `customer_name`, `phone_number`. Response: `id`, `table_number`, `grand_total`, `platform_fee`, `delivery_fee`, `is_delivery`, `status`, `area_id`, `customer_name`, `phone_number`, `checkout_url`, `created_at`, `updated_at`, `orders`. `checkout_url` is the DOKU payment link.
- `GET /v1/storefront/orders/{groupId}` — **storefront, no auth.** Get an order group. Response: same shape as create.
- `GET /v1/orders` — **bearer auth.** List per-branch orders (`?branch_id=`). Item shape: see the confirmed-live shape above.
- `PATCH /v1/orders/{orderId}/status` — update one order's status. Request: `order_status`. Response: `id`, `order_group_id`, `branch_id`, `receipt_number`, `grand_total`, `settlement_bank_account_number`, `total_dpp`, `total_pb1`, `order_status`, `created_at`, `updated_at`, `items`.

### BroadcastReplay

- `GET /v1/broadcast/replay?branch_id=&after_id=` — gap-fill/reconnect endpoint for missed `order.created` events. Item shape: `id`, `event`, `payload`, `created_at`.

### DokuPaymentWebhook

- `POST /v1/webhooks/doku/payment` — **storefront, no auth**, server-to-server. DOKU calls this to confirm payment. Response: `message`.

### Scan / Product (storefront)

- `GET /v1/storefront/scan?table_id=` — **no auth.** Resolve a table QR to its area + operating tenant branches. Response: `table_id`, `table_code`, `area_id`, `tenant_branches`, `outlet_categories`.
- `GET /v1/storefront/products?branch_id=` — **no auth.** Menu for a branch. Response: `categories`, `items`.
- `GET /v1/storefront/products/{id}/modifiers` — **no auth.** List a product's modifier groups.
- `GET /v1/storefront/modifier-groups/{id}` — **no auth.** Get one modifier group. Response: `id`, `name`, `description`, `is_required`, `min_selections`, `max_selections`, `sequence_order`, `is_active`, `options`.

### ProductModifierGroup

- `GET /v1/products/{productId}/modifier-groups` — list a product's modifier groups.
- `POST /v1/products/{productId}/modifier-groups/sync` — replace the set. Request: `modifier_group_ids`.

### User / Role

- `GET /v1/users` — list.
- `POST /v1/users` — create. Request: `username`, `password`, `card_uid`, `role_id`, `branch_ids`, `unit_scopes`.
- `PATCH /v1/users/{id}` — update. Request: `is_active`, `password`.
- `GET /v1/roles` — list. **No documented response schema at all** (bare `{type: object}`) — confirm shape live before relying on it.

### Misc

- `GET /ping` — **no auth**, health check. Response: `message`.

## Re-extracting this doc

The spec is not exposed as a static file — it's embedded as
`docs.apiDescriptionDocument = {...}` inside a `<script>` tag on the docs
page HTML. To regenerate:

```bash
curl -s "https://dtw-cms.gadingemerald.com/docs/api/" -o docs.html
python -c "
import json
with open('docs.html', encoding='utf-8') as f:
    content = f.read()
marker = 'docs.apiDescriptionDocument = '
start = content.index(marker) + len(marker)
end = content.index('};\n    })();', start)
spec = json.loads(content[start:end+1])
json.dump(spec, open('openapi_spec.json', 'w'), indent=1)
"
```

Then walk `spec['paths']` (each path → method → `summary`, `tags`,
`requestBody`, `responses.200.content['application/json'].schema`) to rebuild
the endpoint tables above. `spec['components']['schemas']` only has the
`Create*Request` / `Update*Request` / `Upload*Request` bodies — response
shapes are inlined per-endpoint, not reusable named schemas.
