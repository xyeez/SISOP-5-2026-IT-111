# Soal 1 - Farewell Party

**Deskripsi Tugas:**
Pada soal ini, praktikan ditugaskan untuk merakit sebuah sistem operasi Linux minimalis dari awal (*from scratch*). Sistem operasi ini harus dikompilasi menggunakan Kernel Linux 6.1.1 dan utilitas BusyBox. OS yang dibangun harus mendukung mode *single-user* dan *multi-user* dengan pembagian hak akses direktori yang spesifik. Selain itu, OS harus dapat dikemas menjadi *bootable ISO*, memiliki konektivitas internet, dan dilengkapi dengan *package manager* kustom bernama `party` untuk menginstal serta menjalankan program FUSE.

##  Struktur Direktori
Sistem dibangun dengan mematuhi hierarki folder berikut:
```text
soal_1/
├── .config       # Konfigurasi kernel linux
├── backup.sh     # Skrip backup hasil build
├── iso.sh        # Skrip pembuat bootable ISO
├── kernel.sh     # Skrip kompilasi kernel Linux 6.1.1
├── multi.sh      # Skrip pembuat multi-user filesystem
├── osboot/       # Direktori penyimpanan hasil build
├── qemu.sh       # Skrip untuk menjalankan QEMU
└── single.sh     # Skrip pembuat single-user filesystem
```

##  Implementasi Sistem

### 1. Kompilasi Kernel (Soal 2)
Skrip `kernel.sh` mengunduh dan mengompilasi Linux Kernel versi 6.1.1. Hasil kompilasi disimpan sebagai `osboot/bzImage`.
```bash
./kernel.sh
```

### 2. Single-User Filesystem (Soal 3)
Skrip `single.sh` merakit direktori dasar (*rootfs*) menggunakan BusyBox. Hanya terdapat pengguna `root` dengan akses penuh ke seluruh sistem. Hasil rakitan di-compress menjadi `osboot/single.gz`.
```bash
./single.sh
```

### 3. Multi-User Filesystem & Access Control (Soal 4)
Skrip `multi.sh` merakit *rootfs* untuk banyak pengguna dengan pembagian direktori `/home`. Hasilnya di-compress menjadi `osboot/multi.gz`.
* Menampilkan ASCII Art **Farewell Party** saat login.
* **Pengguna & Password:** `root` (root123), `henn` (henn123), `hann` (hann123), `viii` (viii123), `kids` (kids123).
* **Hak Akses:** Diatur sesuai spesifikasi (misal: `root` akses ke semua direktori, `henn` hanya ke `/home/*`, dst), sedangkan *user* lain memiliki hak eksekusi dan baca terbatas.
```bash
./multi.sh
```

### 4. Bootable ISO (Soal 5)
Skrip `iso.sh` menggabungkan `single.gz` dan `multi.gz` ke dalam satu media bootable bernama `osboot/farewell.iso`.
```bash
./iso.sh
```

### 5. Eksekusi Emulator QEMU (Soal 6)
Skrip `qemu.sh` digunakan untuk memuat sistem operasi ke dalam emulator QEMU dengan parameter khusus untuk mengaktifkan jaringan.
```bash
./qemu.sh --single  # Boot langsung ke mode single-user
./qemu.sh --multi   # Boot langsung ke mode multi-user
./qemu.sh --all     # Boot melalui CD-ROM ISO
```

### 6. Manajemen Arsip / Backup (Soal 7)
Skrip `backup.sh` mengompres seluruh berkas hasil *build* ke dalam `osboot/farewell_backup_[DDMMYYYY-HHMMSS].zip`, lalu menghapus direktori *rootfs* mentah agar penyimpanan lebih efisien.
```bash
./backup.sh
```

### 7. Konektivitas Internet (Soal 8)
Sistem memiliki pengaturan jaringan otomatis (IP `10.0.2.15` dan DNS `8.8.8.8`) untuk terhubung ke internet luar. Pengujian menggunakan perintah:
```bash
ping -c 4 8.8.8.8
wget [http://example.com](http://example.com)
```

### 8. Package Manager & FUSE (Soal 9 & 10)
Terdapat *package manager* bawaan bernama `party` yang mendukung bypass enkripsi TLS. Skrip ini digunakan untuk memasang dan menjalankan program eksekusi *filesystem* tiruan (FUSE).
```bash
party install fuse
simple_fuse
```
