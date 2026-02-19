# API Documentation: Face Recognition Attendance

## Endpoint Information

| Property | Value |
|----------|-------|
| URL | `/recognize_global.php` |
| Method | `POST` |
| Content-Type | `image/jpeg` (raw binary) |

---

## Request

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | string | Yes | User identifier (NIP/username) |
| `sample_id` | integer | No | Sample ID for face recognition (default: `0`) |
| `orientasi` | string | No | Image orientation: `"L"` for landscape, leave empty for portrait |

### Request Body

- **Type**: Raw binary (image/jpeg)
- **Content**: Captured face image in JPEG format

### Example Request

#### JavaScript (Fetch API)

```javascript
async function submitFaceRecognition(userId, sampleId, imageBlob, orientation = '') {
  const params = new URLSearchParams({
    user_id: userId,
    sample_id: sampleId,
    orientasi: orientation
  });

  const response = await fetch(`/recognize_global.php?${params.toString()}`, {
    method: 'POST',
    body: imageBlob,
    headers: {
      'Content-Type': 'image/jpeg'
    }
  });

  return response.text();
}

// Usage
const result = await submitFaceRecognition('12345', 1, imageBlob, 'L');
```

#### JavaScript (Axios)

```javascript
import axios from 'axios';

async function submitFaceRecognition(userId, sampleId, imageBlob, orientation = '') {
  const response = await axios.post(`/recognize_global.php`, imageBlob, {
    params: {
      user_id: userId,
      sample_id: sampleId,
      orientasi: orientation
    },
    headers: {
      'Content-Type': 'image/jpeg'
    }
  });

  return response.data;
}
```

---

## Response

### Success Response

| Status | Response Body |
|--------|---------------|
| Face recognized & attendance recorded | `OK` |

### Error Response

| Response Body | Description |
|---------------|-------------|
| `ERROR: Failed to update presensi` | Attendance record could not be updated |
| `FAILED` or other messages | Face not recognized or processing error |

### Response Format

- **Type**: `text/plain`
- **Encoding**: UTF-8

---

## Response Handling Example

```javascript
const result = await submitFaceRecognition(userId, sampleId, imageBlob, orientation);

switch (result) {
  case 'OK':
    console.log('Attendance recorded successfully!');
    break;
  case 'ERROR: Failed to update presensi':
    console.error('Database update failed');
    break;
  default:
    console.error('Face recognition failed:', result);
}
```

---

## Flow Diagram

```
┌─────────────────┐
│  Send Image     │
│  + Query Params │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     Landscape?     ┌──────────────────┐
│ Receive Image   │───────────────────▶│ Rotate & Retry   │
└────────┬────────┘                    │ (up to 3 tries)  │
         │                             └────────┬─────────┘
         │ Portrait                             │
         │                                      │
         ▼                                      ▼
┌─────────────────┐                    ┌──────────────────┐
│ Face Recognition│◀───────────────────│ Python Script    │
│ (recognize.py)  │                    │ recognize.py     │
└────────┬────────┘                    └──────────────────┘
         │
         ▼
    ┌────┴────┐
    │SUCCESS? │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
   YES       NO
    │         │
    ▼         ▼
┌───────┐ ┌────────┐
│Update │ │ Return │
│Presensi│ │ Error  │
└───┬───┘ └────────┘
    │
    ▼
┌───────┐
│Return │
│ "OK"  │
└───────┘
```

---

## Notes

1. **Image Orientation**: If `orientasi=L`, the system will attempt face recognition with multiple rotations (CCW 90°, CW 90°, original) until successful.

2. **User Lookup**: The `user_id` is combined with `@pnp.ac.id` to form the institutional email for database lookup.

3. **Threshold**: Face recognition threshold is fetched from the database per user (`appusrImgThreshold`).

4. **Attendance Table**: Automatically determined based on user type:
   - `presensi_dsn_YYYY` for teaching staff ("Staf Pengajar")
   - `presensi_kpd_YYYY` for other staff

5. **Session Recording**: On success, attendance is marked as `H` (Hadir/Present) for the current date.
