# API Reference — Tenant & Busboy

**Untuk:** Developer aplikasi Tenant & Busboy
**Pendamping dokumen:** `tenant-busboy-order-flow.md` (baca itu dulu untuk konteks alurnya — dokumen ini murni detail payload request/response tiap endpoint)

Base URL: `/v1`. Semua endpoint di bawah butuh header `Authorization: Bearer {access_token}` kecuali disebutkan lain.

---

## Format Envelope (berlaku di semua endpoint)

**Sukses biasa:**
```json
{
  "meta": { "success": true, "message": "Success", "code": 200, "trace_id": "..." },
  "data": { /* ... */ }
}
```

**Sukses dengan pagination** (tambahan `pagination_meta` di dalam `meta`):
```json
{
  "meta": {
    "success": true, "message": "Success", "code": 200, "trace_id": "...",
    "pagination_meta": { "current_page": 1, "page_size": 15, "total_items": 42, "total_pages": 3 }
  },
  "data": [ /* ... */ ]
}
```

**Error** (`errors` sejajar dengan `meta`, bukan di dalamnya):
```json
{
  "meta": { "success": false, "message": "Pesan error", "code": 422, "trace_id": "..." },
  "errors": { "field_name": ["Pesan validasi."] }
}
```
`errors` biasanya `null` kecuali untuk 422 validasi field (shape `{field: [pesan, ...]}`, standar Laravel).

**Mapping error generik** (di luar error spesifik tiap endpoint): 429 "Too many attempts. Please try again later.", 401 "Unauthenticated.", 403 "You do not have permission to perform this action.", 404 "The requested resource was not found.", 500 "An unexpected error occurred. Please try again."

> Catatan implementasi: beberapa endpoint busboy (`claim`/`complete` untuk delivery & confirmation) menulis error 403/404/409/422-nya langsung inline di controller, bukan lewat exception class khusus — jadi pesannya persis seperti yang ditulis di bawah, tidak ada "kode error" terpisah untuk dicocokkan selain string pesannya.

---

## Realtime (Laravel Reverb)

Server broadcast pakai **Laravel Reverb**, yang protokolnya kompatibel dengan **Pusher** — jadi SDK client yang dipakai cukup SDK Pusher biasa (`pusher-js`/`laravel-echo` untuk web, atau SDK Pusher-compatible untuk mobile seperti `pusher-websocket-android`/`pusher-websocket-swift`), tidak perlu SDK khusus Reverb.

### Konfigurasi koneksi

| Parameter | Nilai |
|---|---|
| `key` (app key) | nilai `REVERB_APP_KEY` dari environment — minta ke backend, beda tiap environment |
| `wsHost` | nilai `REVERB_HOST` |
| `wsPort` | nilai `REVERB_PORT` (non-TLS) |
| `wssPort` | nilai `REVERB_PORT` (TLS) |
| `forceTLS` | `true` kalau `REVERB_SCHEME=https`, `false` kalau `http` (dev lokal biasanya `http`) |
| `enabledTransports` | `['ws', 'wss']` |
| `cluster` | **tidak dipakai** (field khusus Pusher Cloud; Reverb self-hosted tidak butuh ini — isi string apa saja/`mt1`, diabaikan) |
| Auth endpoint | `{BASE_URL}/broadcasting/auth` (lihat bawah) |

> Belum ada kode frontend existing (CMS pakai polling biasa, bukan websocket) yang bisa dijadikan contoh config persis — nilai env di atas harus dikonfirmasi/diminta ke backend per environment (dev/staging/prod beda host & key).

### Otorisasi channel

Semua channel yang dipakai tenant/busboy adalah **private channel** (bukan public, bukan presence). Endpoint auth-nya `POST` (atau `GET`) ke `/broadcasting/auth`, didaftarkan otomatis oleh Laravel dan **butuh header `Authorization: Bearer {access_token}`** yang sama persis dengan token REST API (lewat Sanctum) — SDK Pusher/Echo pada umumnya punya opsi untuk menyisipkan header custom ini di request auth (`authEndpoint` + `auth.headers`).

Aturan otorisasi per channel (`routes/channels.php`):
- `private-branch.{branchId}` — diizinkan kalau token punya scope `{"type":"branch","tenant_branch_id":"{branchId}"}`. **Dipakai tenant.**
- `private-zone.{zoneId}` — diizinkan kalau token punya scope `{"type":"zone","zone_id":"{zoneId}"}`. **Dipakai busboy.** Busboy multi-zona harus subscribe ke **setiap** `private-zone.{zoneId}` miliknya satu-satu (satu koneksi socket bisa subscribe banyak channel sekaligus) — jangan cuma subscribe zona pertama, ini beda dari keterbatasan `GET /busboy/order-confirmations`/`GET /busboy/deliveries` yang memang hanya baca zona pertama.

`branchId`/`zoneId` didapat dari `scopes` pada response login (lihat bawah).

### Daftar event

| Event (`broadcastAs`) | Channel | Kapan dikirim | Payload |
|---|---|---|---|
| `order.created` | `private-branch.{branch_id}` | Order baru masuk setelah pembayaran sukses (dikirim per-order, bukan per-invoice) | `{ "broadcast_event_id": 123, "order_group": { /* OrderGroupResource */ }, "order": { /* OrderResource, shape sama endpoint #1 */ } }` |
| `order-confirmation.created` | `private-zone.{zone_id}` | ada item ditolak kitchen (sisa item diterima), butuh keputusan customer lewat busboy | `{ "broadcast_event_id": ..., ...payload confirmation, shape sama endpoint #11 }` |
| `order-confirmation.claimed` | `private-zone.{zone_id}` | busboy klaim tugas konfirmasi | sama shape endpoint #11 |
| `order-confirmation.resolved` | `private-zone.{zone_id}` | keputusan customer (PROCEED/CANCEL) sudah dicatat | sama shape endpoint #11 |
| `delivery.created` | `private-zone.{zone_id}` | order jadi READY & butuh diantar | sama shape endpoint #7 |
| `delivery.claimed` | `private-zone.{zone_id}` | busboy klaim delivery | sama shape endpoint #7 |
| `delivery.completed` | `private-zone.{zone_id}` | delivery selesai | sama shape endpoint #7 |

Semua event di atas `shouldBroadcastNow()` — dikirim langsung tanpa antrean/delay. Setiap payload selalu dibungkus satu field tambahan `broadcast_event_id` (integer, auto-increment dari tabel internal `broadcast_events`) di luar field data aslinya — field ini yang dipakai sebagai `after_id` untuk endpoint replay.

### Reconnect / catch-up event yang terlewat

Kalau koneksi socket sempat putus, jangan asumsikan semua event selama offline akan terkirim ulang otomatis oleh Reverb — pakai `GET /v1/broadcast/replay` (lihat endpoint #5) dengan `after_id` = `broadcast_event_id` terakhir yang diterima sebelum putus, untuk ambil event yang terlewat.

⚠️ **Replay saat ini hanya mendukung channel tenant (`branch_id`)**, belum ada versi untuk channel zona (busboy) — kalau app busboy butuh mekanisme reconnect serupa, perlu diminta ke backend untuk ditambahkan.

---

## 0. Login (prasyarat — dua app butuh token ini)

```
POST /v1/auth/login
```
Tidak butuh header Authorization.

**Request** — login tenant maupun busboy sama-sama pakai username+password:
```json
{ "method": "password", "username": "tenant_ops", "password": "secret123" }
```
Validasi: `method` wajib `password`; `username` wajib; `password` wajib.

**Response sukses:**
```json
{
  "access_token": "1|abcdef...",
  "user": {
    "id": "uuid", "name": "...", "phone": "...", "username": "...", "email": "...",
    "role": "tenant_keeper", "created_at": "2026-10-09T10:00:00.000000Z"
  },
  "abilities": ["orders:view", "orders:process", "..."],
  "scopes": [
    { "type": "branch", "tenant_branch_id": "uuid" }
  ]
}
```
Untuk busboy, `scopes` isinya bisa **lebih dari satu** `{ "type": "zone", "zone_id": "uuid" }` (busboy sekarang bisa multi-zona — lihat catatan keterbatasan di dokumen flow soal endpoint list yang cuma baca zona pertama).

Masa berlaku token: 8 jam.

**Error:**
- 401 `"Invalid credentials."` — username/password salah.
- 403 `"Account is inactive."` — akun ditemukan tapi nonaktif.

---

## Endpoint Tenant

### 1. `GET /v1/orders` — Daftar Order

**Query params:**
| Param | Wajib | Tipe | Keterangan |
|---|---|---|---|
| `branch_id` | ✅ | uuid | Branch tenant yang mau dilihat order-nya |
| `status` | — | string | Salah satu nilai `OrderStatus` (`PENDING`, `PREPARING`, dst) |
| `date` | — | `YYYY-MM-DD` | Filter tanggal order dibuat |

Contoh: `GET /v1/orders?branch_id=abc-123&status=PENDING`

**Response** (`data` = array, **tidak dipaginasi**, urut terbaru dulu):
```json
{
  "meta": { "success": true, "message": "Success", "code": 200, "trace_id": "..." },
  "data": [
    {
      "id": "order-uuid",
      "order_group_id": "group-uuid",
      "branch_id": "branch-uuid",
      "receipt_number": "RCP-20261009-ABCDEF",
      "invoice_number": "INV-20261009-XYZ123",
      "grand_total": 45000,
      "total_dpp": 40540.54,
      "total_pb1": 4459.46,
      "delivery_fee": 5000,
      "consumption_type": "dine_in",
      "order_status": "PENDING",
      "table_number": "A12",
      "customer_name": "Budi Santoso",
      "is_delivery": true,
      "branch_name": null,
      "brand_name": null,
      "created_at": "2026-10-09T10:00:00.000000Z",
      "updated_at": "2026-10-09T10:00:00.000000Z",
      "items": [
        {
          "id": "item-uuid",
          "order_id": "order-uuid",
          "product_id": "product-uuid",
          "product_name": "Nasi Goreng Spesial",
          "unit_price": 40000,
          "dpp_price": 36036.04,
          "pb1_price": 3963.96,
          "quantity": 1,
          "subtotal": 40000,
          "status": "PENDING",
          "rejected_quantity": 0,
          "notes": "Pedas level 2",
          "rejection_reason": null,
          "modifiers": [
            { "id": "mod-uuid", "order_item_id": "item-uuid", "modifier_group": "Level Pedas", "modifier_option": "Level 2", "dpp_price": 0, "pb1_price": 0, "total_price": 0 }
          ]
        }
      ],
      "status_history": [
        { "id": "hist-uuid", "from_status": null, "to_status": "PENDING", "source": "CUSTOMER", "actor_user_id": null, "actor_name": null, "created_at": "2026-10-09T09:59:50.000000Z" }
      ]
    }
  ]
}
```

> **Catatan**: `branch_name`/`brand_name` selalu `null` di endpoint ini (dan di endpoint #3, #4) karena relasi `branch` memang tidak di-load di query-nya — jangan andalkan dua field ini, pakai `branch_id` yang sudah kamu tahu dari context app.

---

### 2. `POST /v1/orders/{order}/process` — Terima/Tolak Item

**Request** — isinya **cuma item yang DITOLAK**; item yang tidak disebutkan otomatis dianggap diterima penuh:
```json
{
  "rejected_items": [
    { "id": "item-uuid", "reason": "Stok habis", "quantity": 1 }
  ]
}
```
| Field | Wajib | Keterangan |
|---|---|---|
| `rejected_items` | — (boleh `[]`/dikosongkan = terima semua) | array |
| `rejected_items[].id` | ✅ | uuid order item |
| `rejected_items[].reason` | ✅ | string, maks 1000 karakter |
| `rejected_items[].quantity` | — | integer ≥1. Dikosongkan = tolak seluruh qty baris itu |

**Response sukses:** `data` = `null`.
```json
{ "meta": { "success": true, "message": "Order berhasil diproses.", "code": 200, "trace_id": "..." }, "data": null }
```

**Hasil status order** (otomatis, tidak dikirim di request):
- Tidak ada `rejected_items` sama sekali → `PREPARING`.
- Ada yang ditolak tapi masih ada sisa item diterima → `AWAITING_CONFIRMATION` (menunggu keputusan customer lewat busboy, lihat endpoint #10).
- Semua item ditolak/tidak ada sisa yang diterima → `CANCELLED` langsung.

**Error:**
- 404 `"Order tidak ditemukan."`
- 422 `"Order belum dibayar, belum bisa diproses."` — group belum `PAID`.
- 422 `"Order hanya bisa diproses saat statusnya PENDING."`

---

### 3. `PATCH /v1/orders/{order}/status` — Ubah Status Manual

**Request:**
```json
{ "order_status": "READY" }
```
Field wajib **`order_status`** (bukan `status`), harus salah satu nilai enum `OrderStatus` yang valid sebagai tujuan transisi (lihat tabel transisi di dokumen flow).

**Response sukses:** `data` = object `Order` (shape sama seperti satu item di endpoint #1).

**Error:**
- 404 `"Order tidak ditemukan."`
- 422 `"Order belum dibayar, belum bisa diproses."`
- 422 `"Tidak bisa mengubah status order dari {dari} ke {ke}."` — transisi tidak diizinkan (mis. `PENDING` langsung ke `DELIVERING`).

Mengirim status yang **sama** dengan status saat ini bukan error (no-op).

---

### 4. `POST /v1/orders/{order}/complete-pickup` — Selesaikan Self-Pickup

**Request:**
```json
{ "pickup_code": "048213" }
```
`pickup_code` wajib string (tidak divalidasi format panjang di sisi server — konvensinya 6 digit, dari `GeneratePickupCodeAction` yang dipanggil customer).

**Response sukses:** `data` = object `Order`, status sudah `COMPLETED`/`PARTIAL_COMPLETED`.
```json
{ "meta": { "success": true, "message": "Order berhasil diselesaikan.", "code": 200, "trace_id": "..." }, "data": { /* Order */ } }
```

**Error:**
- 404 `"Order tidak ditemukan."`
- 422 `"Order ini adalah delivery, bukan self pickup."`
- 422 `"Order belum siap diambil (status harus READY)."`
- 422 `"Kode pickup tidak sesuai."` — termasuk kalau kode belum pernah di-generate customer sama sekali.

---

### 5. `GET /v1/broadcast/replay` — Catch-up Event Terlewat

Dipakai kalau koneksi websocket app tenant sempat putus — ambil event yang terjadi selama itu.

**Query params:** `branch_id` (wajib, uuid), `after_id` (wajib, integer ≥0 — id event terakhir yang sudah diterima).

**Response:**
```json
{
  "meta": { "success": true, "message": "Success", "code": 200, "trace_id": "..." },
  "data": [
    { "id": 1024, "event": "order.created", "payload": { /* sesuai event-nya */ }, "created_at": "2026-10-09T10:00:00.000000Z" }
  ]
}
```

**Error:** 403 `"Unauthorized."` — kalau `branch_id` yang diminta tidak ada di scope token.

> Belum ada endpoint replay setara untuk busboy per-zona — kalau dibutuhkan, perlu dikonfirmasi ke tim backend.

---

## Endpoint Busboy

### 6. `POST /v1/busboy/fcm-token` — Daftarkan FCM Token

**Request:**
```json
{ "fcm_token": "device-fcm-token-string" }
```
**Response:** `data` = `null`. Upsert — aman dipanggil berkali-kali (update token lama tiap device baru login).

---

### 7. `GET /v1/busboy/deliveries` — Daftar Delivery Pending

**Query opsional:** `status` (tidak divalidasi ketat, dikirim apa adanya ke filter).

⚠️ Hanya membaca **zona pertama** dari token (lihat catatan di dokumen flow).

**Response** (array, tiap item):
```json
{
  "id": "delivery-uuid",
  "status": "PENDING_PICKUP",
  "order_group_id": "group-uuid",
  "order_id": "order-uuid",
  "zone_id": "zone-uuid",
  "busboy_user_id": null,
  "table_number": "A12",
  "customer_name": "Budi Santoso",
  "claimed_at": null,
  "delivered_at": null,
  "created_at": "2026-10-09T10:05:00.000000Z",
  "orders": [
    {
      "order_id": "order-uuid",
      "receipt_number": "RCP-20261009-ABCDEF",
      "brand_name": "Janji Jiwa",
      "items": [
        { "product_id": "...", "product_name": "Nasi Goreng Spesial", "unit_price": 40000, "subtotal": 40000, "quantity": 1, "notes": "Pedas level 2" }
      ]
    }
  ]
}
```
`orders` dipertahankan sebagai array untuk kompatibilitas bentuk, tapi **selalu cuma berisi 1 elemen** (satu delivery = satu order, bukan satu invoice).

**Error:** 403 `"Zone context not found."` — token tidak punya scope zona.

---

### 8. `GET /v1/busboy/deliveries/history` — Riwayat Delivery Busboy Ini

**Query opsional:** `from` (`YYYY-MM-DD`), `to` (`YYYY-MM-DD`, harus ≥ `from`), `status`.

Tidak kena keterbatasan zona — filter berdasarkan `busboy_user_id` milik sendiri (semua zona ikut, kalau multi-zona). Shape response item sama persis dengan endpoint #7.

---

### 9. `POST /v1/busboy/deliveries/{delivery}/claim` — Klaim Delivery

Tidak ada request body — cukup `{delivery}` di URL.

**Response sukses:** `data` = object delivery (shape sama endpoint #7, sekarang `busboy_user_id` & `claimed_at` terisi), order otomatis pindah `READY` → `DELIVERING`.
```json
{ "meta": { "success": true, "message": "Delivery claimed.", "code": 200, "trace_id": "..." }, "data": { /* delivery */ } }
```

**Error:**
- 404 `"Delivery not found."`
- 422 `"Anda sudah mencapai batas maksimal {n} pengantaran bersamaan untuk area ini."` — dari setting `max_concurrent_deliveries_per_busboy` di Area, dihitung dari delivery yang masih `CLAIMED` di area yang sama (lintas zona dalam satu area ikut terhitung).
- 409 `"Delivery could not be claimed. Another busboy may have taken it first."` — race condition, busboy lain lebih cepat klaim.

---

### 10. `POST /v1/busboy/deliveries/{delivery}/complete` — Selesaikan Delivery

Tidak ada request body.

**Response sukses:** `data` = `null`. Order otomatis pindah `DELIVERING` → `COMPLETED`/`PARTIAL_COMPLETED` (tergantung ada item yang sempat ditolak/diterima sebagian sebelumnya atau tidak).
```json
{ "meta": { "success": true, "message": "Delivery completed.", "code": 200, "trace_id": "..." }, "data": null }
```

**Error:**
- 404 `"Delivery not found."`
- 403 `"You did not claim this delivery."` — delivery diklaim busboy lain.
- 422 `"Delivery is not in CLAIMED status."` — misal sudah selesai sebelumnya.

---

### 11. `GET /v1/busboy/order-confirmations` — Daftar Konfirmasi Pending

**Query opsional:** `status`. ⚠️ Sama seperti endpoint #7, hanya baca **zona pertama** token.

**Response** (array, tiap item — **termasuk detail item yang ditolak**, supaya busboy tahu apa yang harus disampaikan ke customer):
```json
{
  "id": "confirmation-uuid",
  "order_id": "order-uuid",
  "order_group_id": "group-uuid",
  "zone_id": "zone-uuid",
  "busboy_user_id": null,
  "status": "PENDING",
  "decision": null,
  "table_number": "A12",
  "customer_name": "Budi Santoso",
  "receipt_number": "RCP-20261009-ABCDEF",
  "brand_name": "Janji Jiwa",
  "claimed_at": null,
  "resolved_at": null,
  "created_at": "2026-10-09T10:03:00.000000Z",
  "items": [
    { "product_name": "Es Teh Manis", "quantity": 2, "rejected_quantity": 1, "status": "PARTIALLY_ACCEPTED", "rejection_reason": "Stok habis" }
  ]
}
```

---

### 12. `POST /v1/busboy/order-confirmations/{confirmation}/claim` — Klaim Tugas Konfirmasi

Tidak ada request body.

**Response sukses:** `data` = object confirmation (shape sama endpoint #11, `busboy_user_id` & `claimed_at` terisi).

**Error:** 409 `"Confirmation could not be claimed. Another busboy may have taken it first."`

---

### 13. `POST /v1/busboy/order-confirmations/{confirmation}/resolve` — Kirim Keputusan Customer

**Request:**
```json
{ "decision": "CANCEL" }
```
`decision` wajib, nilai **persis** `"PROCEED"` atau `"CANCEL"` (huruf besar semua — bukan `"proceed"`/`"cancel"`).

**Response sukses:** `data` = object confirmation terbaru (status sudah `RESOLVED`, shape sama endpoint #11).
```json
{ "meta": { "success": true, "message": "Keputusan customer berhasil dicatat.", "code": 200, "trace_id": "..." }, "data": { /* confirmation */ } }
```

Efek per decision:
| Decision | Order jadi | Refund |
|---|---|---|
| `PROCEED` | `PREPARING` | Item yang sudah ditolak kitchen tetap direfund |
| `CANCEL` | `CANCELLED` | Item ditolak kitchen + sisa item yang belum diputuskan, semuanya direfund |

**Error:** 422 `"Konfirmasi tidak ditemukan atau sudah diselesaikan."`

---

## Ringkasan Cepat

| # | Method | Path | Request body |
|---|---|---|---|
| 0 | POST | `/auth/login` | `method`, `username`, `password` |
| 1 | GET | `/orders` | — (query: `branch_id`, `status`, `date`) |
| 2 | POST | `/orders/{order}/process` | `rejected_items[]` |
| 3 | PATCH | `/orders/{order}/status` | `order_status` |
| 4 | POST | `/orders/{order}/complete-pickup` | `pickup_code` |
| 5 | GET | `/broadcast/replay` | — (query: `branch_id`, `after_id`) |
| 6 | POST | `/busboy/fcm-token` | `fcm_token` |
| 7 | GET | `/busboy/deliveries` | — (query: `status`) |
| 8 | GET | `/busboy/deliveries/history` | — (query: `from`, `to`, `status`) |
| 9 | POST | `/busboy/deliveries/{id}/claim` | — |
| 10 | POST | `/busboy/deliveries/{id}/complete` | — |
| 11 | GET | `/busboy/order-confirmations` | — (query: `status`) |
| 12 | POST | `/busboy/order-confirmations/{id}/claim` | — |
| 13 | POST | `/busboy/order-confirmations/{id}/resolve` | `decision` |
