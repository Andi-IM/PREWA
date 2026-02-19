# Training Model API

API untuk melakukan training wajah ke model. Dipanggil setelah user selesai upload semua foto.

---

## Cara Pakai

### URL
```
POST /process_train_global.php
```

### Parameter URL (Query String)

| Parameter | Wajib | Tipe | Keterangan |
|-----------|-------|------|------------|
| `sample_id` | ✅ Ya | number | ID user/sample yang sudah upload foto |

---

## Response

Server akan mengembalikan **text biasa** (bukan JSON).

| Response | Artinya |
|----------|---------|
| `"OK"` | ✅ Training sukses atau sudah pernah di-training |
| `"TRAIN_FAILED"` | ❌ Training gagal (foto kurang/belum valid) |
| `"ERROR: ..."` | ❌ Error sistem |

---

## Kapan Dipanggil?

```
Upload foto 1 → Upload foto 2 → ... → Semua foto selesai → Panggil API ini
```

Panggil API ini **setelah** semua foto berhasil diupload. Jangan panggil sebelum user selesai upload.

---

## Contoh Kode

### Fetch API
```javascript
async function startTraining(sampleId) {
  const url = `/process_train_global.php?sample_id=${sampleId}`;
  
  const response = await fetch(url, {
    method: 'POST'
  });
  
  const result = await response.text();
  
  if (result === 'OK') {
    console.log('Training sukses! ✅');
    return true;
  } else {
    console.log('Training gagal ❌:', result);
    return false;
  }
}

// Cara pakai
startTraining(123);
```

### Axios
```javascript
import axios from 'axios';

async function startTraining(sampleId) {
  const response = await axios.post(
    `/process_train_global.php`,
    null,
    {
      params: {
        sample_id: sampleId
      }
    }
  );
  
  return response.data === 'OK';
}
```

### React - Setelah Upload Selesai
```jsx
function UploadComplete({ sampleId }) {
  const [training, setTraining] = useState(false);
  const [status, setStatus] = useState('');
  
  const handleTrain = async () => {
    setTraining(true);
    setStatus('Sedang training...');
    
    const res = await fetch(`/process_train_global.php?sample_id=${sampleId}`, {
      method: 'POST'
    });
    
    const result = await res.text();
    setTraining(false);
    
    if (result === 'OK') {
      setStatus('Training selesai! Wajah sudah dikenali.');
    } else {
      setStatus('Training gagal. Pastikan foto cukup dan jelas.');
    }
  };
  
  return (
    <div>
      <p>Semua foto sudah diupload.</p>
      <button onClick={handleTrain} disabled={training}>
        {training ? 'Processing...' : 'Mulai Training'}
      </button>
      {status && <p>{status}</p>}
    </div>
  );
}
```

### React - Dengan Loading State Lengkap
```jsx
function TrainingPage({ sampleId, onComplete }) {
  const [state, setState] = useState('idle'); // idle | training | success | failed
  const [error, setError] = useState('');
  
  const startTraining = async () => {
    setState('training');
    setError('');
    
    try {
      const res = await fetch(`/process_train_global.php?sample_id=${sampleId}`, {
        method: 'POST'
      });
      
      const result = await res.text();
      
      if (result === 'OK') {
        setState('success');
        onComplete?.();
      } else {
        setState('failed');
        setError(result);
      }
    } catch (err) {
      setState('failed');
      setError('Koneksi error');
    }
  };
  
  return (
    <div>
      {state === 'idle' && (
        <button onClick={startTraining}>Mulai Training</button>
      )}
      
      {state === 'training' && (
        <div>
          <span>Training wajah...</span>
          <progress />
        </div>
      )}
      
      {state === 'success' && (
        <div className="success">✅ Wajah berhasil dikenali!</div>
      )}
      
      {state === 'failed' && (
        <div className="error">
          ❌ Training gagal: {error}
          <button onClick={startTraining}>Coba Lagi</button>
        </div>
      )}
    </div>
  );
}
```

---

## Tips

1. **Pastikan sudah upload foto**: Training butuh minimal beberapa foto valid
2. **Training butuh waktu**: Proses bisa memakan waktu beberapa detik, tampilkan loading indicator
3. **Idempoten**: API aman dipanggil berkali-kali. Kalau sudah pernah training, akan langsung return `"OK"`
4. **Tidak perlu body**: Request tidak butuh body, cukup query parameter

---

## Flow Singkat

```
User upload foto → Selesai → Panggil training → Tunggu → "OK" = selesai
```

---

## Notes

- Training bisa gagal jika foto kurang atau tidak valid
- Kalau gagal, user perlu upload foto tambahan lalu training ulang
- Status training disimpan di database, jadi aman jika user refresh halaman
