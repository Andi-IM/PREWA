# Upload Foto API

API untuk upload foto wajah yang akan otomatis di-crop dan divalidasi.

---

## Cara Pakai

### URL
```
POST /upload_foto_global.php
```

### Parameter URL (Query String)

| Parameter | Wajib | Tipe | Nilai | Keterangan |
|-----------|-------|------|-------|------------|
| `sample_id` | ✅ Ya | number | `123` | ID user/sample |
| `index` | ⭕ Tidak | number | `1`, `2`, `3` | Nomor urut foto (biar tidak dobel upload) |
| `orientasi` | ⭕ Tidak | string | lihat tabel di bawah | Arah foto |

**Pilihan `orientasi`:**

| Nilai | Kapan Dipakai |
|-------|---------------|
| `""` (kosong) | Foto tegak/vertikal (default) |
| `"L"` | Foto miring/landscape (server akan coba rotate otomatis) |
| `"CCW90"` | Foto perlu diputar 90° ke kiri |
| `"CW90"` | Foto perlu diputar 90° ke kanan |

---

## Response

Server akan mengembalikan **text biasa** (bukan JSON).

| Response | Artinya |
|----------|---------|
| `"OK"` | ✅ Sukses! Foto berhasil upload dan lolos validasi |
| `"5"` (angka) | ❌ Gagal. Angka adalah index foto berikutnya yang bisa dipakai |

---

## Contoh Kode

### Fetch API
```javascript
async function uploadFoto(file, sampleId, index, orientasi = '') {
  const url = `https://domain.com/upload_foto_global.php?sample_id=${sampleId}&index=${index}&orientasi=${orientasi}`;
  
  const response = await fetch(url, {
    method: 'POST',
    body: file, // file dari input[type="file"]
    headers: {
      'Content-Type': 'image/jpeg'
    }
  });
  
  const result = await response.text();
  
  if (result === 'OK') {
    console.log('Upload sukses! ✅');
    return true;
  } else {
    console.log('Upload gagal, coba lagi ❌');
    return false;
  }
}

// Cara pakai
const fileInput = document.querySelector('#foto');
uploadFoto(fileInput.files[0], 123, 1);
```

### Axios
```javascript
import axios from 'axios';

async function uploadFoto(file, sampleId, index, orientasi = '') {
  const response = await axios.post(
    `https://domain.com/upload_foto_global.php`,
    file,
    {
      params: {
        sample_id: sampleId,
        index: index,
        orientasi: orientasi
      },
      headers: {
        'Content-Type': 'image/jpeg'
      }
    }
  );
  
  return response.data === 'OK';
}
```

### React + Input File
```jsx
function UploadForm({ sampleId }) {
  const [uploading, setUploading] = useState(false);
  
  const handleUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    setUploading(true);
    
    const url = `/upload_foto_global.php?sample_id=${sampleId}&index=1`;
    const res = await fetch(url, {
      method: 'POST',
      body: file
    });
    
    const result = await res.text();
    setUploading(false);
    
    if (result === 'OK') {
      alert('Foto berhasil diupload!');
    } else {
      alert('Foto gagal divalidasi. Coba foto lain.');
    }
  };
  
  return (
    <input 
      type="file" 
      accept="image/jpeg" 
      onChange={handleUpload}
      disabled={uploading}
    />
  );
}
```

---

## Tips

1. **Format gambar**: Hanya JPEG/JPG
2. **Ukuran minimal**: File harus > 1000 bytes (tidak boleh terlalu kecil)
3. **Jangan pakai FormData**: Langsung kirim file-nya saja sebagai body
4. **Index**: Gunakan nomor berbeda untuk setiap foto agar tidak dianggap duplikat

---

## Flow Singkat

```
User pilih foto → Kirim ke API → Server crop & validasi → Response "OK" atau angka
```

- Kalau `"OK"` → Foto bagus, lanjut upload foto berikutnya
- Kalau angka → Foto tidak lolos validasi, minta user ambil foto ulang

---

## Notes

- Pastikan user sudah login (ada session)
- Server akan otomatis crop foto agar fokus ke wajah
- Foto yang gagal akan disimpan terpisah untuk analisis
