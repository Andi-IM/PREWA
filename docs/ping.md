# Ping API

API untuk mengecek status koneksi dan hari kerja.

---

## Endpoint

| Mode | URL |
|------|-----|
| Local/VPN | `POST /ping.php` |
| Global/WFA | `POST /ping_global.php` |

---

## Request

### Form Data

| Parameter | Wajib | Nilai |
|-----------|-------|-------|
| `get_status` | ✅ Ya | `"ON"` |

---

## Response

```json
{
  "sts_akses": "OK",
  "ip_client": "192.168.1.100",
  "sts_kerja": "OK"
}
```

| Field | Keterangan |
|-------|------------|
| `sts_akses` | `"OK"` = valid. Global: bisa juga `"NO_WFA"` jika di luar periode WFA |
| `ip_client` | IP address client |
| `sts_kerja` | `"OK"` = hari kerja, `"0"` = hari libur |

---

## Contoh Kode

```javascript
async function ping(isWFA = false) {
  const url = isWFA ? '/ping_global.php' : '/ping.php';
  
  const formData = new FormData();
  formData.append('get_status', 'ON');
  
  const res = await fetch(url, { method: 'POST', body: formData });
  return res.json();
}

// Cara pakai
const status = await ping(false); // local/VPN
const status = await ping(true);  // WFA
```

---

## Notes

- Response kosong jika parameter tidak valid
- Global mode memiliki validasi periode WFA tambahan
