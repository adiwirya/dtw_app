# API Guide — Tenant & Busboy

Dokumentasi endpoint baru untuk integrasi sistem tenant dan aplikasi busboy.

## Autentikasi

Semua endpoint di dokumen ini (kecuali disebutkan lain) butuh header:

```
Authorization: Bearer <access_token>
```

Token didapat dari `POST /api/v1/auth/login` (lihat bagian [Response Login](#response-login-name--phone) di bawah).

Semua response mengikuti format standar:
```json
{
  "meta": { "success": true, "message": "...", "code": 200, "trace_id": "..." },
  "data": { ... }
}
```
Response error:
```json
{
  "meta": { "success": false, "message": "Pesan error di sini", "code": 422 },
  "errors": null
}
```

---

## 1. Tenant Tolak Sebagian Pesanan

### 1.1 Proses Order (Tenant)

```
POST /api/v1/orders/{order}/process
```

Dipakai tenant untuk menerima/menolak item dalam 1 order. **Setiap item yang ditolak wajib disertai alasan.**

**Body:**
```json
{
  "rejected_items": [
    { "id": "uuid-item-1", "reason": "Bahan habis" },
    { "id": "uuid-item-2", "reason": "Menu sedang tidak tersedia" }
  ]
}
```

| Field | Tipe | Wajib | Ket |
|---|---|---|---|
| `rejected_items` | array | ❌ | kosongkan/hilangkan kalau semua item diterima |
| `rejected_items[].id` | uuid | ✅ (per item) | id `OrderItem` |
| `rejected_items[].reason` | string | ✅ (per item) | alasan bebas, maks 1000 karakter |

**Logika status yang dihasilkan:**
- **Semua item ditolak** → order langsung `CANCELLED`, tidak ada busboy dilibatkan.
- **Sebagian item ditolak** → order jadi `AWAITING_CONFIRMATION`, busboy di zone yang sama otomatis dinotifikasi (FCM) untuk mendatangi customer.
- **Tidak ada yang ditolak** → order jadi `PREPARING` seperti biasa.

**Response sukses (200):**
```json
{ "meta": { "success": true, "message": "Order berhasil diproses.", "code": 200 }, "data": null }
```

**Error:**
| Kondisi | Kode |
|---|---|
| Order tidak ditemukan | 404 |
| Order status bukan `PENDING` | 422 |
| `rejected_items[].reason` kosong | 422 (validasi) |

---

### 1.2 Daftar Konfirmasi Pending (Busboy)

```
GET /api/v1/busboy/order-confirmations?status=PENDING
```

Menampilkan daftar order yang sedang `AWAITING_CONFIRMATION` di zone busboy yang login (zone diambil dari scope token, bukan parameter).

**Query param:** `status` (opsional) — `PENDING` | `CLAIMED` | `RESOLVED`

**Response:**
```json
{
  "data": [
    {
      "id": "uuid-confirmation",
      "order_id": "uuid-order",
      "order_group_id": "uuid-group",
      "zone_id": "uuid-zone",
      "busboy_user_id": null,
      "status": "PENDING",
      "decision": null,
      "table_number": "A12",
      "customer_name": "Budi",
      "receipt_number": null,
      "brand_name": "Kopi Kenangan",
      "claimed_at": null,
      "resolved_at": null,
      "created_at": "2026-09-23T08:00:00Z",
      "items": [
        { "product_name": "Es Kopi Susu", "quantity": 2, "status": "REJECTED", "rejection_reason": "Bahan habis" },
        { "product_name": "Croissant", "quantity": 1, "status": "ACCEPTED", "rejection_reason": null }
      ]
    }
  ]
}
```
Kalau `403 "Zone context not found."` → token busboy tidak punya scope zone (masalah setup akun, bukan bug di kode caller).

---

### 1.3 Claim Konfirmasi (Busboy)

```
POST /api/v1/busboy/order-confirmations/{confirmation}/claim
```

Tidak ada body. Idempoten secara atomik — kalau sudah diambil busboy lain duluan, dapat error.

**Response sukses:** payload sama seperti item di list 1.2, dengan `status: "CLAIMED"`, `busboy_user_id` terisi.

**Error:** `409 "Confirmation could not be claimed. Another busboy may have taken it first."`

---

### 1.4 Resolve Konfirmasi (Busboy)

```
POST /api/v1/busboy/order-confirmations/{confirmation}/resolve
```

Dipanggil setelah busboy dapat jawaban dari customer di meja.

**Body:**
```json
{ "decision": "PROCEED" }
```
`decision`: `"PROCEED"` (lanjut tanpa item yang ditolak) atau `"CANCEL"` (batalkan semua).

**Efek:**
- `PROCEED` → order jadi `PREPARING`.
- `CANCEL` → order jadi `CANCELLED`, dan item yang tadinya `ACCEPTED` ikut diubah jadi `REJECTED` (supaya data item konsisten dengan hasil akhir).

**Response:** payload konfirmasi dengan `status: "RESOLVED"`, `decision` terisi.

---

## 2. Import Produk via Excel

Alur 2 langkah: **parse dulu** (preview + validasi), baru **import** setelah tenant isi kategori & gambar per baris di UI.

### 2.1 Parse File Excel

```
POST /api/v1/products/bulk-import/parse
Content-Type: multipart/form-data
```

**Form fields:**
| Field | Tipe | Wajib | Ket |
|---|---|---|---|
| `brand_id` | uuid | ✅ | |
| `file` | file | ✅ | `.xlsx`/`.xls`, maks 5MB. Kolom wajib di Excel: `name`, `price`. Opsional: `sku`, `description` |

**Response:**
```json
{
  "data": {
    "brand_id": "uuid-brand",
    "total": 3,
    "valid_count": 2,
    "items": [
      { "row": 2, "name": "Nasi Goreng", "sku": "NG001", "description": null, "price": 25000, "errors": [] },
      { "row": 3, "name": "", "sku": null, "description": null, "price": null, "errors": ["Nama produk wajib diisi.", "Harga tidak valid."] },
      { "row": 4, "name": "Mie Ayam", "sku": "NG001", "description": null, "price": 20000, "errors": ["SKU duplikat dengan baris lain di file ini."] }
    ]
  }
}
```
`row` = nomor baris asli di file Excel (baris 1 = header), **bukan** index array — dipakai kalau user perlu balik cek file aslinya.

Baris dengan `errors` tidak kosong tidak boleh dikirim ke step import (filter di sisi client, atau minta user perbaiki filenya).

### 2.2 Import (Final Submit)

```
POST /api/v1/products/bulk-import
Content-Type: multipart/form-data
```

Dikirim setelah user lengkapi `category_id` + `image` per baris di preview.

**Form fields:**
```
brand_id: uuid
items[0][name]: string
items[0][sku]: string (opsional)
items[0][description]: string (opsional)
items[0][price]: number
items[0][category_id]: uuid
items[0][image]: file (jpeg/png/webp, maks 5MB, wajib persegi rasio 1:1, min 500×500px)
items[1][...]: ...
```

Semua field per item **wajib** kecuali `sku` dan `description`. Kalau ada 1 baris invalid (kategori tidak match brand, SKU sudah dipakai), **seluruh batch gagal** (tidak ada yang setengah-tersimpan) — response 422 dengan errors per index (`items.0.category_id`, dst).

**Response sukses (201):** array `ProductResource` untuk semua produk yang dibuat.

---

## 3. Self-Pickup — Tenant Input Kode

Alur: customer generate kode (endpoint storefront, di luar scope dokumen ini) → tenant input kode itu untuk menyelesaikan order.

```
POST /api/v1/orders/{order}/complete-pickup
```

**Body:**
```json
{ "pickup_code": "123456" }
```

**Syarat:**
- Order harus **self-pickup** (bukan delivery).
- Order harus berstatus `READY`.
- Kode harus cocok dengan yang di-generate customer.

**Response sukses:** `OrderResource` order yang sudah `COMPLETED`.

**Error:**
| Kondisi | Kode | Pesan |
|---|---|---|
| Order delivery, bukan self-pickup | 422 | "Order ini adalah delivery, bukan self pickup." |
| Order belum `READY` | 422 | "Order belum siap diambil (status harus READY)." |
| Kode salah / belum digenerate | 422 | "Kode pickup tidak sesuai." |

⚠️ Kode pickup **tidak pernah muncul** di endpoint manapun yang dibaca tenant (termasuk `GET /orders`) — satu-satunya cara tahu kodenya adalah customer memberitahukannya langsung. Ini disengaja, supaya kode benar-benar jadi bukti kehadiran customer.

---

## 4. Riwayat Klaim Busboy

```
GET /api/v1/busboy/deliveries/history?from=2026-09-01&to=2026-09-30&status=DELIVERED
```

Menampilkan **hanya pengantaran yang di-claim busboy yang sedang login** (beda dengan `GET /busboy/deliveries` yang menampilkan semua orang di zone).

**Query param (semua opsional):**
| Param | Format | Ket |
|---|---|---|
| `from` | `Y-m-d` | filter `claimed_at >=` |
| `to` | `Y-m-d` | filter `claimed_at <=`, harus setelah/sama dengan `from` |
| `status` | string | `PENDING_PICKUP` / `CLAIMED` / `DELIVERED` |

**Response:** array, tiap item:
```json
{
  "id": "uuid-delivery",
  "status": "DELIVERED",
  "order_group_id": "uuid-group",
  "zone_id": "uuid-zone",
  "busboy_user_id": "uuid-busboy",
  "table_number": "A12",
  "customer_name": "Budi",
  "claimed_at": "2026-09-23T08:05:00Z",
  "delivered_at": "2026-09-23T08:15:00Z",
  "created_at": "2026-09-23T08:00:00Z",
  "orders": [
    {
      "order_id": "uuid-order",
      "receipt_number": "RCP-20260923-ABC123",
      "brand_name": "Kopi Kenangan",
      "items": [
        { "product_id": "uuid-product", "product_name": "Es Kopi Susu", "unit_price": 18000, "subtotal": 36000, "quantity": 2, "notes": null }
      ]
    }
  ]
}
```
Kosongkan semua query param untuk lihat seluruh riwayat busboy tersebut.

---

## 5. Rating (Lihat Rata-rata)

Dua endpoint read-only untuk menampilkan skor rating di UI (tenant maupun aplikasi busboy). **Bukan** endpoint submit rating (itu dipanggil dari sisi customer/storefront, di luar scope dokumen ini).

### 5.1 Rating Tenant Branch

```
GET /api/v1/tenant-branches/{branch}/rating
```
Pakai `Authorization: Bearer <token>` seperti endpoint lain di dokumen ini.

### 5.2 Rating Busboy

```
GET /api/v1/busboys/{user}/rating
```
`{user}` adalah `busboy_user_id` (bisa didapat dari payload delivery, field `busboy_user_id`).

### Response (sama untuk keduanya)

```json
{ "data": { "average": 4.5, "count": 12 } }
```

| Field | Tipe | Ket |
|---|---|---|
| `average` | `number \| null` | **`null` kalau belum ada rating sama sekali** — jangan diperlakukan sebagai `0` (0 berarti rating 0 bintang, padahal rating valid minimal 1) |
| `count` | `number` | jumlah rating yang masuk |

---

## 6. Response Login — `name` & `phone`

```
POST /api/v1/auth/login
```

Response `user{}` sekarang membawa 2 field baru:

```json
{
  "data": {
    "access_token": "1|xxxxxxxxxxxxxxxx",
    "user": {
      "id": "uuid-user",
      "name": "Budi Santoso",
      "phone": "081234567890",
      "username": "budi_tenant",
      "email": "budi@example.com",
      "role": "tenant_keeper"
    },
    "abilities": ["..."],
    "scopes": ["..."]
  }
}
```

| Field baru | Tipe | Ket |
|---|---|---|
| `name` | string | nama lengkap user |
| `phone` | `string \| null` | opsional, bisa `null` kalau belum diisi admin waktu bikin akun |

Field lama (`id`, `username`, `email`, `role`, `abilities`, `scopes`) tidak berubah.
