# Dokumentasi Aplikasi PREWA (Presensi Wajah)

## Daftar Isi
1. [Pendahuluan](#pendahuluan)
2. [Arsitektur Aplikasi](#arsitektur-aplikasi)
3. [Fitur Utama](#fitur-utama)
4. [Alur Kerja Aplikasi](#alur-kerja-aplikasi)
5. [Struktur Direktori](#struktur-direktori)
6. [Konfigurasi API](#konfigurasi-api)
7. [State Management](#state-management)
8. [Komponen Penting](#komponen-penting)
9. [Penjelasan Bisnis Logic](#penjelasan-bisnis-logic)
10. [Instalasi dan Build](#instalasi-dan-build)

---

## Pendahuluan

**PREWA** (Presensi Wajah) adalah aplikasi presensi berbasis pengenalan wajah (face recognition) yang dikembangkan untuk Politeknik Negeri Padang (PNP). Aplikasi ini memungkinkan karyawan/dosen untuk melakukan presensi dengan dua mode:

- **WFO (Work From Office)**: Presensi yang dilakukan di dalam jaringan kantor (WiFi kampus)
- **WFA (Work From Anywhere)**: Presensi yang dapat dilakukan dari luar jaringan kantor

### Kebutuhan Dasar Pemrograman yang Diperlukan
- Pemahaman dasar tentang pemrograman berorientasi objek (OOP)
- Pemahaman tentang Flutter dan Dart
- Pemahaman tentang REST API dan HTTP requests
- Pemahaman tentang state management
- Pemahaman tentang async/await dan Future dalam Dart

---

## Arsitektur Aplikasi

PREWA menggunakan arsitektur **Clean Architecture** dengan pola **Provider** untuk state management. Berikut komponen utamanya:

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer (Screens)                    │
│  HomeScreen, LoginScreen, WfoScreen, WfaScreen, dll       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic (Providers)                │
│  WfoProvider, WfaProvider, LoginProvider, dll              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Services Layer                          │
│  ApiService, StorageService, CrashlyticsService, dll        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  Models (LoginResponse, PingResponse), API Config          │
└─────────────────────────────────────────────────────────────┘
```

### Tech Stack
- **Framework**: Flutter 3+
- **Bahasa**: Dart
- **State Management**: Provider
- **Navigation**: GoRouter
- **HTTP Client**: http package
- **Analytics**: Firebase Analytics
- **Error Tracking**: Firebase Crashlytics
- **Local Storage**: SharedPreferences
- **Camera**: camera package

---

## Fitur Utama

### 1. Home Screen (Layar Utama)
- Tampilan utama aplikasi dengan tombol navigasi ke berbagai fitur
- Menampilkan pesan API jika ada
- Menampilkan versi aplikasi
- Tombol: WFO, WFA, Sample, Presensi, Resample, Exit

### 2. WFO (Work From Office)
Pengecekan keamanan sebelum melakukan presensi di kantor:
1. **Cek Koneksi WiFi**: Memastikan perangkat terhubung ke WiFi kantor (SSID: `WIFI@PNP`)
2. **Validasi Keamanan**: Memvalidasi IP address (harus dimulai dengan `192.168.` atau `10.`)
3. **Cek Jam Kerja**: Memastikan akses dilakukan pada jam kerja (Senin-Jumat, jam 07:00-18:00)
4. **Redirect ke Login**: Jika semua validasi berhasil, arahkan ke halaman login

### 3. WFA (Work From Anywhere)
Pengecekan untuk presensi di luar kantor:
1. **Cek Koneksi Server**: Mengirim ping ke server untuk memverifikasi akses
2. **Cek Status WFA**: Memeriksa apakah WFA diaktifkan untuk user
3. **Cek Hari Kerja**: Memastikan bukan hari libur
4. **Redirect ke Login**: Jika validasi berhasil, arahkan ke halaman login

### 4. Login
- Form input username dan password
- Simpan kredensial secara lokal untuk kemudahan
- Navigasi berdasarkan status training wajah:
  - **Belum Training** → Sample Record Screen
  - **Sudah Training** → Presensi Screen
  - **Perlu Resample** → Resample Screen

### 5. Sample Record (Rekam Sampel Wajah)
- Mengambil 10 foto wajah secara berurutan
- Resize gambar menjadi 600x600 piksel
- Upload foto ke server secara bertahap
- Proses training model wajah di server
- Tampilan progress dan notifikasi keberhasilan/gagal

### 6. Presensi (Ceklok)
- Menampilkan status presensi hari ini
- Tombol untuk melakukan ceklok (presensi masuk)
- Tombol keluar untuk kembali ke halaman utama

### 7. Resample
- Similar dengan Sample Record, tetapi untuk pengguna yang perlu merekam ulang wajah

---

## Alur Kerja Aplikasi

### Alur Kerja WFO
```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ User Klik   │ ──► │ Cek WiFi Terhubung │ ──► │ Cek SSID Wifi    │
│ Tombol WFO  │     │ ke WIFI@PNP       │     │ (WIFI@PNP)       │
└──────────────┘     └───────────────────┘     └──────────────────┘
                                                      │
                                                      ▼
                        ┌───────────────────┐     ┌──────────────────┐
                        │ Cek IP Address     │ ◄── │ Jika SSID Salah  │
                        │ (192.168.x / 10.x)│     │ Tampilkan Error │
                        └───────────────────┘     └──────────────────┘
                              │
                              ▼
                        ┌───────────────────┐     ┌──────────────────┐
                        │ Cek Jam Kerja     │ ──► │ Jika Diluar Jam  │
                        │ (Senin-Jumat,     │     │ Kerja: Error     │
                        │ 07:00-18:00)      │     └──────────────────┘
                        └───────────────────┘
                              │
                              ▼
                        ┌───────────────────┐
                        │ Redirect ke Login │
                        └───────────────────┘
```

### Alur Kerja WFA
```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ User Klik   │ ──► │ Kirim Ping ke     │ ──► │ Cek Response     │
│ Tombol WFA  │     │ Server            │     │ (isValid)        │
└──────────────┘     └───────────────────┘     └──────────────────┘
                                                      │
                                                      ▼
                     ┌──────────────────┐      ┌───────────────────┐
                     │ Cek WFA Disabled │ ◄─── │ Jika Tidak Valid │
                     │ (sts_akses)      │      │ Tampilkan Error  │
                     └──────────────────┘      └───────────────────┘
                              │
                              ▼
                     ┌──────────────────┐      ┌───────────────────┐
                     │ Cek Hari Kerja   │ ─────│ Jika Bukan Hari  │
                     │ (sts_kerja)      │      │ Kerja: Error     │
                     └──────────────────┘      └───────────────────┘
                              │
                              ▼
                     ┌──────────────────┐
                     │ Redirect ke Login│
                     └──────────────────┘
```

### Alur Kerja Login
```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ User Input   │ ──► │ Kirim Request     │ ──► │ Cek Response     │
│ Username &   │     │ ke Server         │     │ (status = OK)    │
│ Password     │     └───────────────────┘     └──────────────────┘
└──────────────┘                                        │
                                                        ▼
                                          ┌────────────────────────┐
                                          │ Ambil Data:            │
                                          │ - token                │
                                          │ - nama_user            │
                                          │ - sample_id            │
                                          │ - status_training      │
                                          │ - ceklok, tgl_kerja    │
                                          └────────────────────────┘
                                                        │
                                                        ▼
                              ┌───────────────────────────────┐
                              │Berdasarkan Status Training:   │
                              │  - not_trained → SampleRecord│
                              │  - trained → Presensi         │
                              │  - resample_required → Resamp │
                              └───────────────────────────────┘
```

### Alur Kerja Rekam Sampel Wajah
```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ User Klik    │ ──► │ Inisialisasi      │ ──► │ Tampilkan Camera │
│ "Mulai Rekam"│     │ Kamera            │     │ Preview          │
└──────────────┘     └───────────────────┘     └──────────────────┘
                                                      │
                                                      ▼
                        ┌─────────────────────┐    ┌──────────────────┐
                        │ Loop 10 Kali:      │ ◄──│ User Klik        │
                        │ 1. Ambil Foto      │    │ "Ambil Foto"     │
                        │ 2. Resize 600x600  │    └──────────────────┘
                        │ 3. Simpan ke List  │ 
                        └─────────────────────┘
                                │
                                ▼
                    ┌───────────────────────────┐
                    │ Upload Semua Foto ke     │
                    │ Server (Satu per Satu)   │
                    └───────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────────┐
                    │ Proses Training (Train)  │
                    │ Model Wajah di Server     │
                    └───────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────────┐
                    │ Tampilkan Hasil           │
                    │ (Sukses/Gagal)            │
                    └───────────────────────────┘
```

---

## Struktur Direktori

```
lib/
├── config/
│   └── api_config.dart          # Konfigurasi URL dan endpoint API
├── models/
│   ├── login_response.dart      # Model response login
│   ├── ping_response.dart       # Model response ping
│   └── models.dart              # Barrel file untuk exports
├── providers/
│   ├── app_config_provider.dart # Konfigurasi mode WFA/WFO
│   ├── home_provider.dart       # State untuk HomeScreen
│   ├── login_provider.dart      # State dan logic untuk login
│   ├── presensi_provider.dart   # State untuk presensi
│   ├── resample_provider.dart  # State untuk resample
│   ├── sample_record_provider.dart # State untuk rekam sampel
│   ├── storage_provider.dart    # Wrapper untuk local storage
│   ├── wfa_provider.dart       # State dan logic WFA
│   └── wfo_provider.dart       # State dan logic WFO
├── router/
│   └── app_router.dart          # Konfigurasi routing dengan GoRouter
├── screens/
│   ├── home_screen.dart         # Layar utama
│   ├── login_screen.dart       # Layar login
│   ├── presensi_screen.dart    # Layar presensi
│   ├── resample_screen.dart    # Layar resample
│   ├── sample_record_screen.dart # Layar rekam sampel wajah
│   ├── record_success_screen.dart # Layar hasil rekam
│   ├── wfa_screen.dart          # Layar WFA
│   └── wfo_screen.dart         # Layar WFO
├── services/
│   ├── analytics_service.dart  # Firebase Analytics wrapper
│   ├── api_service.dart         # HTTP client untuk API calls
│   ├── crashlytics_service.dart # Firebase Crashlytics wrapper
│   ├── performance_service.dart # Firebase Performance wrapper
│   └── storage_service.dart     # Local storage service
├── firebase_options.dart        # Konfigurasi Firebase
└── main.dart                    # Entry point aplikasi
```

---

## Konfigurasi API

### Base URL
```
https://prewa.pnp.ac.id
```

### Endpoints

| Endpoint | Method | Keterangan |
|----------|--------|------------|
| `/login.php` | POST | Login internal (WFO) |
| `/login_global.php` | POST | Login eksternal (WFA) |
| `/ping.php` | POST | Cek status server (WFO) |
| `/ping_global.php` | POST | Cek status server (WFA) |
| `/whoami.php` | GET | Get current user info |
| `/upload_foto.php` | POST | Upload foto wajah (WFO) |
| `/upload_foto_global.php` | POST | Upload foto wajah (WFA) |
| `/process_train.php` | POST | Proses training wajah (WFO) |
| `/process_train_global.php` | POST | Proses training wajah (WFA) |

### Headers Default
```dart
{
  'Content-Type': 'application/x-www-form-urlencoded',
}
```

### Timeout
- Default: 10 detik
- Short (ping): 2 detik

---

## State Management

Aplikasi menggunakan **Provider** pattern untuk state management. Berikut provider yang tersedia:

### 1. AppConfigProvider
```dart
class AppConfigProvider extends ChangeNotifier {
  bool _isWfa = false;  // Mode WFA atau WFO
  // ...
}
```
Fungsi: Menyimpan konfigurasi mode aplikasi (WFA/WFO)

### 2. LoginProvider
```dart
enum LoginStatus { idle, loading, success, error }
enum LoginNavigationTarget { sampleRecord, presensi, resample }

class LoginProvider extends ChangeNotifier {
  // State
  LoginStatus _status;
  String? _userId;
  String? _password;
  
  // Methods
  Future<LoginResult> login(String username, String password);
  LoginNavigationTarget _mapTrainingStatusToTarget(TrainingStatus? status);
}
```
Fungsi: Mengelola state login dan navigasi berdasarkan status training

### 3. WfoProvider
```dart
enum WfoStatus {
  idle,
  checkingInfrastructure,    // Cek WiFi
  infrastructureError,        // Error WiFi
  validatingSecurity,         // Validasi IP
  securityError,              // Error validasi
  checkingRestrictions,       // Cek jam kerja
  restrictionError,           // Error jam kerja
  redirectToLogin,            // Berhasil, redirect ke login
}

class WfoProvider extends ChangeNotifier {
  static const String validSsid = 'WIFI@PNP';  // SSID yang diperbolehkan
  
  // Methods
  Future<void> startWfoProcess();
  Future<bool> _checkWifiConnection();
  Future<bool> _validateSecurity();
  Future<bool> _checkWorkingRestrictions();
}
```
Fungsi: Mengelola validasi WFO (WiFi, IP, jam kerja)

### 4. WfaProvider
```dart
enum WfaStatus { initial, loading, success, error }

class WfaProvider extends ChangeNotifier {
  // Methods
  Future<bool> checkConnection();
}
```
Fungsi: Mengelola validasi WFA (cek koneksi server)

### 5. SampleRecordProvider
```dart
enum SampleRecordStatus {
  idle,
  readyToCapture,
  processingImage,
  uploading,
  training,
  success,
  error,
  unauthorized,
}

class SampleRecordProvider extends ChangeNotifier {
  final int _targetSamples = 10;  // Jumlah foto yang diperlukan
  List<File> _imgList = [];
  
  // Methods
  Future<void> startRecording();
  Future<void> processImage(XFile xFile);
  Future<bool> _uploadSingleImage(File imageFile, int index);
  Future<void> _startTrainingProcess();
}
```
Fungsi: Mengelola proses rekam sampel wajah (10 foto + training)

### 6. PresensiProvider
```dart
class PresensiProvider extends ChangeNotifier {
  bool _isClockedIn = false;
  String _statusMessage = 'Belum Presensi';
  
  // Methods
  void setData({String? ceklok, String? tglKerja});
  void clockIn();
  void clockOut();
}
```
Fungsi: Mengelola state presensi

### 7. StorageProvider
```dart
class StorageProvider extends ChangeNotifier {
  // Getters
  String? get userId;
  String? get password;
  String? get token;
  String? get namaUser;
  String? get sampleId;
  
  // Methods
  Future<void> saveCredentials({String userId, String password});
  Future<void> saveToken(String token);
  Future<void> saveUserData({String? namaUser, String? sampleId});
  Future<void> clearAll();
}
```
Fungsi: Wrapper untuk akses local storage

---

## Komponen Penting

### ApiService
```dart
class ApiService {
  // Endpoint会根据 AppConfigProvider.isWfa 自动切换
  String get loginEndpoint {
    return _config.isWfa ? ApiEndpoints.loginGlobal : ApiEndpoints.login;
  }
  
  Future<ApiResponse> login({required String username, required String password});
  Future<ApiResponse> ping({Duration? timeout});
  Future<ApiResponse> whoami({Duration? timeout});
}
```
Fungsi: HTTP client yang otomatis memilih endpoint berdasarkan mode (WFA/WFO)

### LoginResponse Model
```dart
class LoginResponse {
  bool isSuccess;
  String? status;
  String? userId;
  String? token;
  String? namaUser;
  String? sampleId;
  TrainingStatus? trainingStatus;  // notTrained, trained, resampleRequired
  String? ceklok;   // Status ceklok hari ini
  String? tglKerja; // Tanggal kerja
}
```

### PingResponse Model
```dart
class PingResponse {
  AccessStatus accessStatus;  // ok, noWfa, invalid
  WorkStatus? workStatus;    // ok, notWorkingDay
  String? ipClient;
  
  bool get isValid;          // accessStatus == ok && workStatus == ok
  bool get isWfaDisabled;    // accessStatus == noWfa
  bool get isNotWorkingDay;  // workStatus == notWorkingDay
}
```

---

## Penjelasan Bisnis Logic

### 1. Validasi WiFi (WFO)
Keperluan bisnis: Memastikan presensi dilakukan di lokasi kantor untuk WFO.

**Logika:**
- Cek apakah perangkat terhubung ke WiFi
- Cek apakah SSID WiFi adalah `WIFI@PNP`
- Cek apakah IP address termasuk dalam range lokal (`192.168.x` atau `10.x`)
- Cek apakah waktu akses berada dalam jam kerja (Senin-Jumat, 07:00-18:00)

**Alasan bisnis:**
- Mencegah presensi dari luar kantor untuk mode WFO
- Memastikan keamanan jaringan internal
- Mencegah penyalahgunaan presensi di luar jam kerja

### 2. Validasi WFA
Keperluan bisnis: Memungkinkan presensi dari luar jaringan kantor.

**Logika:**
- Kirim request ping ke server
- Cek response dari server:
  - `sts_akses = OK` → WFA diaktifkan
  - `sts_akses = NO_WFA` → WFA non-aktif
  - `sts_akses = invalid` → Akses ditolak
- Cek status hari kerja (`sts_kerja`)

**Alasan bisnis:**
- Memberikan fleksibilitas bagi karyawan untuk presensi dari luar kantor
- Server mengontrol siapa yang boleh akses WFA

### 3. Status Training Wajah
Keperluan bisnis: Mengarahkan user ke flow yang sesuai berdasarkan status data wajah mereka.

**Logika:**
- `status_training = 0` → Belum training → Ke Sample Record
- `status_training = 1` → Sudah training → Ke Presensi
- `status_training = 2` atau lainnya → Perlu resample → Ke Resample

**Alasan bisnis:**
- User yang belum memiliki data wajah harus merekam sampel terlebih dahulu
- User yang data wajahnya perlu diupdate (resample) harus merekam ulang
- User yang sudah training langsung ke presensi

### 4. Rekam Sampel Wajah
Keperluan bisnis: Mengumpulkan data wajah untuk training model face recognition.

**Logika:**
- Ambil 10 foto wajah dengan resolusi 600x600
- Upload foto satu per satu ke server
- Server melakukan training model
- Simpan status training

**Alasan bisnis:**
- Model face recognition memerlukan sampel wajah untuk belajar
- 10 foto dengan posisi berbeda meningkatkan akurasi pengenalan

### 5. Presensi (Ceklok)
Keperluan bisnis: Mencatat kehadiran karyawan.

**Logika:**
- Tampilkan status ceklok hari ini
- Jika belum ceklok, tampilkan tombol "Ceklok"
- Setelah ceklok, update status

**Alasan bisnis:**
- Pencatatan kehadiran adalah keharusan untuk payroll dan absensi
- Memudahkan karyawan untuk mencatat kehadiran dengan cepat

---

## Instalasi dan Build

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android SDK (untuk build Android)
- Xcode (untuk build iOS)

### Langkah Instalasi

1. **Clone Repository**
   ```bash
   git clone git@github.com:Andi-IM/PREWA.git
   cd PREWA
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Buat project di Firebase Console
   - Download `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
   - Letakkan di folder yang sesuai

4. **Run Aplikasi**
   ```bash
   flutter run
   ```

### Build Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

### Asset yang Diperlukan
Pastikan folder `assets/` berisi:
- `bg.png` - Background layar
- `app_title.png` - Judul aplikasi
- `logo-pnp.png` - Logo PNP
- `bg_content.png` - Background konten
- `green_bar.png` - Tombol hijau
- `orange_bar.png` - Tombol oranye
- `buttonExit.png` - Tombol keluar

---

## Troubleshooting

### Error: "Harap hubungkan perangkat ke WiFi Kantor"
- Pastikan perangkat terhubung ke WiFi dengan SSID `WIFI@PNP`
- Cek permission lokasi sudah diizinkan

### Error: "Izin lokasi diperlukan untuk memverifikasi WiFi"
- Buka pengaturan → Apps → PREWA → Permissions
- Aktifkan permission "Location"

### Error: "Diluar jam/hari kerja operasional"
- WFO hanya dapat diakses Senin-Jumat, jam 07:00-18:00
- Gunakan WFA jika di luar jam kerja

### Error: "Maaf, Status WFA Non-Aktif"
- Akun Anda tidak diizinkan untuk WFA
- Hubungi administrator

### Error: "Sesi Habis. Login Ulang."
- Token login sudah expired
- Login kembali untuk mendapatkan token baru

---

## API Reference

### Login Request
```
POST /login.php atau /login_global.php
Content-Type: application/x-www-form-urlencoded

Body:
username=XXX&password=XXX

Response:
{
  "status": "OK",
  "user_id": "XXX",
  "token": "XXX",
  "nama_user": "XXX",
  "sample_id": "XXX",
  "status_training": 0/1/2,
  "ceklok": "Y/T",
  "tgl_kerja": "YYYY-MM-DD"
}
```

### Ping Request
```
POST /ping.php atau /ping_global.php
Content-Type: application/x-www-form-urlencoded

Body:
get_status=ON

Response:
{
  "sts_akses": "OK/NO_WFA/invalid",
  "sts_kerja": "OK/null",
  "ip_client": "XXX.XXX.XXX.XXX"
}
```

---

## Catatan Pengembangan

### Keamanan
- Token disimpan secara lokal
- API menggunakan HTTPS
- Validasi dilakukan baik di sisi client maupun server

### Performa
- Image processing dilakukan secara asynchronous
- Firebase Performance Monitoring untuk tracking
- Firebase Crashlytics untuk error tracking

### Analytics
- Screen views tracking
- Button click events
- Custom events untuk tracking user flow
