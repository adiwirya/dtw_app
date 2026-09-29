# API untuk Aplikasi Eksternal — Auth & Device Registration

Dokumen ini khusus untuk 3 endpoint yang dipanggil dari **luar backend** (aplikasi mobile busboy, aplikasi mobile tenant, dan firmware device Sunmi/POS). Endpoint lain di luar dokumen ini (misalnya command internal untuk withdraw Doku) tidak dibahas di sini karena tidak diakses aplikasi eksternal.

Base URL: `https://<host>/api/v1`

## Format Response

Semua response pakai amplop yang sama:

**Sukses:**
```json
{
  "meta": {
    "success": true,
    "message": "Success",
    "code": 200,
    "trace_id": "..."
  },
  "data": { ... }
}
```

**Gagal:**
```json
{
  "meta": {
    "success": false,
    "message": "Pesan error",
    "code": 422,
    "trace_id": "..."
  },
  "errors": { ... }
}
```

`errors` biasanya berisi detail validasi per-field kalau `code` 422, atau `null` untuk error lain.

---

## 1. Device Self-Registration

Dipanggil oleh device Sunmi/POS setiap kali setup wizard-nya dibuka — **bukan** dipanggil manual oleh user.

```
POST /api/v1/devices/register
```

### Auth
Header statis, **bukan** Bearer token login dan **bukan** `X-API-Key` storefront:

| Header | Value |
|---|---|
| `X-Device-Key` | static key, dikonfigurasi di server (`DEVICE_REGISTRATION_KEY`) |

### Request Body

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `device_id` | string, max 100 | ✅ | ID unik fisik device. Unique — kalau `device_id` sudah pernah terdaftar, request ini jadi **update**, bukan error. |
| `fcm_token` | string | ✅ | Token FCM device ini, dipakai buat push notif order masuk. |
| `name` | string, max 255 | tidak | Nama tampilan device. Boleh dikosongkan (diisi belakangan lewat CMS oleh admin tenant). |

Contoh:
```json
{
  "device_id": "SN-A1B2C3D4",
  "fcm_token": "fcm_token_dari_firebase_sdk...",
  "name": "Kasir Lantai 1"
}
```

### Perilaku (penting)
- **Idempotent / upsert** berdasarkan `device_id`:
  - Kalau `device_id` **belum ada** → device baru dibuat, `tenant_branch_id` otomatis `null` (belum di-assign ke branch manapun — ini dilakukan admin lewat CMS setelahnya).
  - Kalau `device_id` **sudah ada** → hanya `fcm_token` yang diupdate (dan `name` kalau dikirim, tidak dikosongkan kalau tidak dikirim). **`tenant_branch_id` tidak pernah ikut ter-reset** oleh call ini — jadi aman dipanggil berkali-kali tiap wizard dibuka tanpa menghapus assignment branch yang sudah di-set admin.
- Response **tidak** mengembalikan `fcm_token` (field sensitif, tidak di-echo balik).

### Response Sukses (201)
```json
{
  "meta": { "success": true, "message": "Device registered successfully.", "code": 201, "trace_id": "..." },
  "data": {
    "id": "uuid",
    "tenant_branch_id": null,
    "device_id": "SN-A1B2C3D4",
    "name": "Kasir Lantai 1",
    "description": null,
    "created_by": null,
    "updated_by": null,
    "created_at": "2026-09-28T00:00:00.000000Z",
    "updated_at": "2026-09-28T00:00:00.000000Z"
  }
}
```

### Response Gagal
| Code | Kondisi |
|---|---|
| 401 | `X-Device-Key` kosong atau salah |
| 422 | `device_id` atau `fcm_token` tidak dikirim / format salah |

---

## 2. Forgot Password (Request Reset Link)

Dipanggil dari aplikasi busboy/tenant saat user tap "Lupa Password" dan input email.

```
POST /api/v1/auth/forgot-password
```

### Auth
Tidak ada — endpoint publik (user yang lupa password otomatis belum punya token login). Dibatasi rate limit **5 request/menit per IP**.

### Request Body
| Field | Tipe | Wajib |
|---|---|---|
| `email` | string, format email | ✅ |

```json
{ "email": "busboy@example.com" }
```

### Perilaku (penting)
- Response **selalu sama** baik email terdaftar maupun tidak — didesain begitu supaya endpoint ini tidak bisa dipakai untuk mengecek apakah suatu email punya akun (anti-enumeration). Jangan tampilkan pesan berbeda di UI app berdasarkan status ini.
- Kalau email terdaftar, sebuah link reset dikirim ke inbox email tersebut. Link ini expired dalam **60 menit**.
- Link yang dikirim mengarah ke halaman web (bukan deep link ke app) untuk set password baru. Kalau app punya UI in-app sendiri untuk reset password, app tidak perlu mengandalkan link email ini — cukup minta user input `token` (dari email) + password baru langsung ke endpoint **Reset Password** di bawah.

### Response (selalu 200, apa pun status email-nya)
```json
{
  "meta": {
    "success": true,
    "message": "Kalau email terdaftar, link reset password sudah kami kirim — cek inbox Anda.",
    "code": 200,
    "trace_id": "..."
  },
  "data": null
}
```

### Response Gagal
| Code | Kondisi |
|---|---|
| 422 | `email` tidak dikirim / bukan format email valid |
| 429 | Lebih dari 5 request dalam 1 menit dari IP yang sama |

---

## 3. Reset Password (Set Password Baru)

Dipanggil setelah user dapat `token` dari email (baik lewat link, atau kalau app punya UI in-app untuk paste/parse token dari email).

```
POST /api/v1/auth/reset-password
```

### Auth
Tidak ada — token reset itu sendiri yang jadi bukti otorisasi. Rate limit **5 request/menit per IP**.

### Request Body
| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `email` | string, format email | ✅ | Harus sama dengan email yang diminta di step Forgot Password |
| `token` | string | ✅ | Token dari email |
| `password` | string, min 8 | ✅ | Password baru |
| `password_confirmation` | string | ✅ | Harus sama dengan `password` |

```json
{
  "email": "busboy@example.com",
  "token": "...",
  "password": "passwordBaru123",
  "password_confirmation": "passwordBaru123"
}
```

### Perilaku (penting)
- Token hanya berlaku **60 menit** sejak diminta, dan **sekali pakai** (langsung invalid setelah dipakai, walau berhasil atau kelewat waktu).
- Berhasil reset password **otomatis logout semua sesi lama** user tersebut (semua Sanctum token direvoke) — kalau user lagi login di device lain, device itu akan ke-logout dan harus login ulang pakai password baru.

### Response Sukses (200)
```json
{
  "meta": { "success": true, "message": "Password berhasil diubah.", "code": 200, "trace_id": "..." },
  "data": null
}
```

### Response Gagal
| Code | Kondisi | Message |
|---|---|---|
| 422 | Token salah / kadaluarsa / sudah dipakai | `Link reset password tidak valid atau sudah kedaluwarsa.` |
| 422 | Validasi field gagal (password < 8 karakter, confirmation tidak cocok, dll) | detail per field di `errors` |
| 429 | Rate limit terlampaui | `Too many attempts. Please try again later.` |
