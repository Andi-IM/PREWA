Tentu, berdasarkan logika blok kode yang Anda unggah, berikut adalah **Dokumentasi API (Unofficial)** yang direkonstruksi. Dokumentasi ini menjelaskan bagaimana sisi klien (aplikasi mobile) berkomunikasi dengan server backend.

---

# Dokumentasi API Sistem Presensi Wajah (PREWA)

**Base URL:** `https://prewa.pnp.ac.id`
**Authentication:** Token-based (dikirim via Header dan Query Parameter)

---

## 1. Upload Sampel Wajah

Endpoint ini digunakan untuk mengunggah file foto wajah satu per satu.

* **Endpoint:** `/upload_foto.php`
* **Method:** `POST`
* **Content-Type:** `multipart/form-data` (atau raw binary file, tergantung konfigurasi server PHP)

### Request Headers

| Key | Value | Deskripsi |
| --- | --- | --- |
| `X-API-TOKEN` | `{token_user}` | Token otentikasi unik pengguna. |

### Query Parameters (URL)

Parameter ini disambung langsung pada URL (GET parameters) meskipun method-nya POST.

| Parameter | Tipe | Wajib | Deskripsi |
| --- | --- | --- | --- |
| `token` | String | Ya | Token sesi pengguna (sama dengan header). |
| `sample_id` | String | Ya | ID unik untuk sesi pengambilan sampel ini. |
| `index` | Integer | Ya | Nomor urut foto (1-10). Rumus klien: `counter + (batch_index * 10)`. |
| `orientasi` | String | Ya | `P` untuk Portrait, `L` untuk Landscape. |

### Request Body

* **File:** Binary image data (file foto yang telah di-resize ke 600x600px).

### Response

* **200 OK:**
* Body: `"OK"`
* *Artinya:* File berhasil disimpan di server.


* **401 Unauthorized:**
* Body: `"NO_LOGIN"`
* *Artinya:* Sesi token habis atau tidak valid. Aplikasi akan memaksa logout.


* **Lainnya:**
* Dianggap sebagai error koneksi/server oleh aplikasi.



---

## 2. Proses Training Data (Finalisasi)

Endpoint ini dipanggil setelah seluruh sampel foto (misal: 10 foto) berhasil diunggah. Tujuannya untuk memicu server agar memproses data wajah tersebut menjadi model pengenalan.

* **Endpoint:** `/process_train.php`
* **Method:** `GET`

### Request Headers

| Key | Value | Deskripsi |
| --- | --- | --- |
| `X-API-TOKEN` | `{token_user}` | Token otentikasi unik pengguna. |

### Query Parameters (URL)

| Parameter | Tipe | Wajib | Deskripsi |
| --- | --- | --- | --- |
| `token` | String | Ya | Token sesi pengguna. |
| `sample_id` | String | Ya | ID unik sampel yang akan diproses. |

### Response

* **200 OK:**
* Body: `"OK"`
* *Artinya:* Data wajah berhasil divalidasi dan diproses (trained). Aplikasi akan pindah ke layar `Sampel_2`.


* **401 Unauthorized:**
* Body: `"NO_LOGIN"`
* *Artinya:* Sesi tidak valid.



---

### Catatan Pengembang (Developer Notes)

1. **Redundansi Token:** Sistem saat ini mengirimkan token di dua tempat sekaligus: di **Header** (`X-API-TOKEN`) dan di **URL** (`?token=...`). Pastikan sisi server memvalidasi salah satu atau keduanya untuk keamanan maksimal.
2. **Indeks Upload:** Logika klien menggunakan `index = numUpload + (idxUpload * 10)`. Ini memungkinkan fitur *retry* (coba lagi). Jika batch pertama gagal di foto ke-3, batch berikutnya bisa melanjutkan atau menimpa indeks yang sesuai tanpa merusak urutan data di server.
3. **Error Handling:** Aplikasi klien hanya mengenali string respon `"OK"` sebagai sukses. Respon lain (kosong, error message PHP, JSON object) akan dianggap gagal.