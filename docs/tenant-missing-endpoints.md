# Tenant App — Endpoint Gaps vs UI

What the tenant (merchant) flavor's UI needs from the backend that
`docs/api-reference.md` has no working endpoint for today. Same format as
`docs/busboy-missing-endpoints.md`: each gap lists the screen, what the app
shows instead, what's needed, and the code seam to wire up. The tenant flow
is much further along than busboy's — Order (accept/reject/ready) and Menu
(list/create/update/toggle) are real and live — so most of what's below is
narrow field-level gaps on otherwise-working endpoints, not whole screens of
mock data. `laporan` (reports) is the one exception: it's entirely fake.

Cross-checked against `api.json` as of 2026-09-04.

## Menu Saya (`menu-saya`, `tambah-menu`, `menu-diisi`)

`GET/POST/PUT /v1/products` backs name, category, price, description, and
active/inactive — those are real. Everything below is a field the design
calls for that `Product` (`lib/features/tenant/data/models/product.dart`)
has nowhere to read from.

### 1. Tag field
- **Where:** `tambah-menu` form's tag chips (e.g. "Chicken", "Combo Meal").
- **Now:** display-only — `tambah_menu_screen.dart` seeds a hardcoded
  `_tags` list for the prefilled prototype state and never sends it anywhere.
- **Needs:** a `tags` (or similar) field on `POST`/`PUT /v1/products`.
- **Wire up at:** `_TambahMenuScreenState._tags` and the save call in
  `lib/features/tenant/presentation/screens/tambah_menu_screen.dart`.

### 2. Discount fields
- **Where:** `tambah-menu`'s dedicated "Diskon" card — percentage, price,
  and valid-date inputs.
- **Now:** display-only, per Open Question 3 in
  `ai_specs/0002-tenant-merchant-app/spec.md` ("2 discount fields —
  percentage + price + valid date. Exact field semantics/validation
  unknown.").
- **Needs:** discount fields on the product schema — semantics (flat vs
  percentage, one active discount vs scheduled ones) still need product
  sign-off, not just an API addition.
- **Wire up at:** `_diskonCard()` in `tambah_menu_screen.dart`.

### 3. Stock / quantity
- **Where:** `menu-saya` list rows imply stock ("Sisa N porsi" appears in
  the design and in `laporan`'s low-stock card).
- **Now:** no stock field anywhere on `Product` —
  `lib/features/tenant/data/models/product.dart`'s own doc comment flags
  this as a known gap.
- **Needs:** a stock/quantity field on the product schema, or a dedicated
  inventory endpoint if stock is tracked separately from the product record.
- **Wire up at:** `Product.toMenuItemData()` in `product.dart`.

### 4. "Populer" (pinned/best-seller) flag
- **Where:** `menu-saya` row badge — replaces the old "best seller" concept
  per L6 (`ai_specs/0002-tenant-merchant-app/interview-ledger.md`).
- **Now:** `MenuItemData.popular` always defaults to `false` —
  `Product.toMenuItemData()` has no source field to read it from.
- **Needs:** an `is_popular` (or `is_pinned`) boolean on the product
  schema, ideally settable via `PUT /v1/products/{id}` alongside
  `is_active`.
- **Wire up at:** `Product.fromJson`/`toMenuItemData()` in `product.dart`.

### 5. Per-branch product availability — documented but broken
- **Where:** `menu-saya`'s active/inactive toggle, if it's meant to be
  branch-scoped rather than brand-wide.
- **Now:** `GET/PATCH /v1/tenant-branches/{branch}/product-availability...`
  **is in the OpenAPI spec but 404s on the live server** (confirmed
  2026-08-31 — see `docs/api-reference.md`'s "Confirmed gaps" section). The
  toggle currently uses the product's own brand-level `is_active` via
  `PUT /v1/products/{id}` instead, so a product's active state is shared
  across every branch that sells it, not per-branch.
- **Needs:** the backend to actually implement the endpoint it already
  documents, if per-branch availability is a real requirement — otherwise
  this should be removed from the spec rather than left as a dead route.
- **Wire up at:** `MenuList.setActive` in
  `lib/features/tenant/presentation/providers/menu_provider.dart` — the
  `TODO`/comment there already tracks this.

### 6. Photo upload — not wired, not a backend gap
- **Where:** `tambah-menu`'s photo picker.
- **Now:** tap is a no-op; `_photoCard()` in `tambah_menu_screen.dart` never
  calls anything.
- **Note:** `POST /v1/products/{id}/image` already exists and works (JPEG/
  PNG/WebP, max 5MB — see `docs/api-reference.md`) and `Product.imageUrl`
  already reads `image_url` back. This is a client-side wiring gap, **not**
  a missing endpoint — listed here only so it isn't mistaken for one.

## Kelola Varian / Tambah Varian (modifier groups)

`GET/POST/PUT /v1/modifier-groups` (+ options) are real and live.

### 7. "Digunakan di N menu" usage count
- **Where:** `kelola-varian` list — footer line under each variant showing
  how many menus reference it.
- **Now:** `VariantData.usedInMenuCount` is nullable and stays `null` —
  `variant_provider.dart`'s own doc comment: "No API source exists for this
  yet — null hides the footer that shows it."
- **Needs:** either a `used_in_products_count` field on
  `GET /v1/modifier-groups`, or a way to derive it (e.g. a reverse lookup on
  `GET /v1/products/{productId}/modifier-groups`, which exists but is
  per-product, not per-group — expensive to fan out over every product just
  to count usage).
- **Wire up at:** `VariantData` construction in
  `lib/features/tenant/presentation/providers/variant_provider.dart`.

## Laporan (report dashboard)

**Entirely mock.** There is no reporting/analytics endpoint on the live API
at all — `laporan_provider.dart`'s own comment confirms this
(`TODO(open-question)`, Open Questions 5+7 in the spec). Every number on the
screen is fabricated:

- Summary card (total revenue + delta vs yesterday).
- Four metric tiles (total orders, average order value, completed orders,
  items sold — each with a trend delta).
- Hourly sales line chart + weekly sales trend chart.
- Busy-hours bar chart + "Rekomendasi" text callout.
- Top-selling items list.
- Low-stock list (blocked on the same stock-field gap as Menu Saya above).
- Menu-performance pie/donut chart (revenue share per item) + "Insight" text.
- Peak-hours bars + "Tips" text callout.
- Three "auto insight" text callouts.
- The `Selasa, 13 Mei 2026` date label and `['Semua', 'Hari', 'Minggu',
  'Bulan', 'Tahun', 'Custom']` filter pills — filtering isn't wired to
  anything real either, since there's no data to filter.

- **Needs:** a tenant reporting/analytics endpoint (likely several: a
  summary/metrics endpoint, a time-series endpoint for the charts, and a
  top-items/low-stock endpoint), scoped by branch and by the date-range
  filter the UI already has pill affordances for. Whether the "Rekomendasi"/
  "Insight"/"Tips" text callouts are server-generated or a client-side rule
  over the numbers is a product question, not just an API gap.
- **Wire up at:** `laporanReportProvider` in
  `lib/features/tenant/presentation/providers/laporan_provider.dart` —
  currently a synchronous provider returning `const` data; swap for an
  async repository fetch per the file's own `TODO`.

## Admin (tenant profile/status, `admin-offline` / `admin-online`)

`GET /v1/tenant-branches/{id}` backs the tenant name and join date — those
are real. `TenantAdminInfo`
(`lib/features/tenant/data/models/tenant_admin_info.dart`) already documents
its own gaps clearly and the screen already hides each row rather than
fabricate a value, so this is a short list of already-known nulls:

### 8. Booth/location, rating, contact, operating hours
- **Where:** the hero header's booth label + rating chip, and the
  "Informasi Tenant"/"Jam Operasional" cards.
- **Now:** all `null` — the branch endpoint has no booth/location, rating,
  contact, or operating-hours fields, confirmed live.
- **Needs:** those fields added to `GET /v1/tenant-branches/{id}` (or a
  dedicated tenant-profile endpoint).
- **Wire up at:** `TenantBranch.toTenantAdminInfo` in
  `lib/features/tenant/data/models/tenant_branch.dart`.

## Login (shared with busboy)

Tenant and busboy share one login screen/flow. "Lupa Password?" has no
destination for either flavor — see item 7 in
`docs/busboy-missing-endpoints.md` rather than duplicating it here.

## Summary table

| # | Screen | Missing endpoint | Priority |
|---|--------|-------------------|----------|
| 1 | Menu Saya / Tambah Menu | Tag field on product | Low |
| 2 | Tambah Menu | Discount fields (needs product sign-off too) | Medium |
| 3 | Menu Saya / Laporan | Stock/quantity field | Medium — blocks 2 screens |
| 4 | Menu Saya | "Populer" pin flag | Low |
| 5 | Menu Saya | Per-branch availability (spec exists, 404s live) | Medium — backend bug, not a gap to spec |
| 6 | Tambah Menu | *(not a gap — endpoint exists, just unwired)* | — |
| 7 | Kelola Varian | "Digunakan di N menu" usage count | Low |
| — | Laporan | Full reporting/analytics endpoint(s) | **High** — entire tab is fake data |
| 8 | Admin | Booth, rating, contact, operating hours | Low — already gracefully hidden |
