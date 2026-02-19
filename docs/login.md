# Login API

API untuk login user.

---

## Endpoint

| Mode | URL |
|------|-----|
| Local/VPN | `POST /login.php` |
| Global/WFA | `POST /login_global.php` |

---

## Request

### Form Data

| Parameter | Wajib | Keterangan |
|-----------|-------|------------|
| `username` | ✅ Ya | Username user |
| `password` | ✅ Ya | Password user |

---

## Response

### Success
```json
{
  "token": "a1b2c3d4e5f6...",
  "status": "OK",
  "nama_user": "Ahmad Fauzi",
  "sample_id": 123,
  "status_training": 1,
  "ceklok": 0,
  "tgl_kerja": "Senin, 17.2.2025"
}
```

| Field | Keterangan |
|-------|------------|
| `token` | Simpan di localStorage untuk request selanjutnya |
| `status` | `"OK"` = login sukses |
| `nama_user` | Nama lengkap |
| `sample_id` | ID sample wajah untuk upload/training |
| `status_training` | `0` = belum training, `1` = sudah training |
| `ceklok` | `0` = belum check-in, `1` = sudah check-in |
| `tgl_kerja` | Tanggal hari ini (format Indonesia) |

### Gagal
```json
{ "status": "ERROR", "message": "Missing parameters" }
{ "status": "FAIL", "message": "User tidak ditemukan" }
{ "status": "FAIL", "message": "Password salah" }
```

---

## Contoh Kode

```javascript
async function login(username, password, isWFA = false) {
  const url = isWFA ? '/login_global.php' : '/login.php';
  
  const formData = new FormData();
  formData.append('username', username);
  formData.append('password', password);
  
  const res = await fetch(url, { method: 'POST', body: formData });
  const data = await res.json();
  
  if (data.status === 'OK') {
    localStorage.setItem('token', data.token);
    localStorage.setItem('sample_id', data.sample_id);
    return data;
  }
  
  throw new Error(data.message);
}

// Cara pakai
const user = await login('fauzi', 'password123', false); // local/VPN
const user = await login('fauzi', 'password123', true);  // WFA
```

### React
```jsx
function LoginForm({ onLoginSuccess }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Auto-detect mode
  const isWFA = !window.location.hostname.startsWith('192.168.');
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const user = await login(username, password, isWFA);
      onLoginSuccess(user);
    } catch (err) {
      setError(err.message);
    }
    
    setLoading(false);
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input placeholder="Username" value={username} onChange={e => setUsername(e.target.value)} />
      <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} />
      <button disabled={loading}>{loading ? 'Loading...' : 'Login'}</button>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
```

---

## Flow Setelah Login

```
Login sukses → Cek status_training
  → 0: User perlu upload foto & training
  → 1: User bisa langsung presensi
```

---

## Notes

- Local mode: hanya dari jaringan kantor/VPN
- Global mode: dari internet dengan validasi WFA
- Response format sama untuk kedua mode
