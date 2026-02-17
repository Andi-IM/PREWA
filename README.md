# PREWA - Presensi Berbasis Wajah

Aplikasi mobile untuk perekaman data presensi wajah.


### Core Features
- **WFO Presensi**: Mendeteksi wajah pegawai dengan lingkup lingkungan perusahaan.
- **WFA Presensi**: Melakukan presensi di mana saja.

### Tech Stack & Infrastructure

- **Frontend**: Flutter
- **Backend**: PHP

### Alur Kerja Perekaman Data Presensi Wajah

**1. Otentikasi dan Keamanan Sesi**
Sebelum proses dimulai, sistem melakukan verifikasi identitas di latar belakang. Sistem memastikan bahwa sesi pengguna masih aktif dan sah untuk mencegah akses atau perekaman data yang tidak diotorisasi.

**2. Standarisasi dan Perekaman Data Otomatis**

* **Otomatisasi Proses:** Sistem memandu pengguna untuk mengambil sejumlah sampel foto wajah (target standar: 10 sampel) secara otomatis berurutan tanpa mengharuskan pengguna menekan tombol kamera berulang kali.
* **Optimasi Kualitas:** Setiap foto yang diambil secara otomatis dikalibrasi dan disesuaikan ukurannya. Ini bertujuan untuk menyeimbangkan antara kualitas pengenalan wajah yang akurat dengan efisiensi beban data saat pengiriman.

**3. Sinkronisasi Data Bertahap**
Setelah sampel terkumpul, sistem mengirimkan paket data ke server secara terstruktur (satu per satu). Selama proses ini, pengguna diberikan visibilitas melalui indikator progres agar mereka mengetahui bahwa sistem sedang bekerja memproses pengiriman data mereka.

**4. Penanganan Kendala Cerdas (Smart Recovery)**
Ini adalah nilai tambah utama dari sistem:

* **Efisiensi Waktu Pengguna:** Jika terjadi gangguan jaringan atau server (misalnya *timeout*) yang menyebabkan sebagian data gagal terkirim, sistem **tidak akan** memaksa pengguna mengulang keseluruhan proses dari awal.
* **Tindak Lanjut Spesifik:** Sistem secara cerdas mengidentifikasi berapa banyak data yang gagal (misalnya 2 dari 10 gagal). Sistem kemudian hanya akan meminta pengguna untuk mengambil ulang 2 sampel yang kurang tersebut, sehingga secara drastis mengurangi potensi frustrasi pengguna.

**5. Finalisasi dan Pemrosesan Akhir**
Setelah seluruh sampel wajah tervalidasi dan berhasil masuk ke server, aplikasi akan memicu perintah penyelesaian. Server kemudian akan memproses (*training*) data tersebut untuk diaktifkan sebagai profil presensi pengguna. Pengguna akan menerima konfirmasi visual bahwa pendaftaran wajah telah sukses dan diarahkan ke tahapan selanjutnya.
