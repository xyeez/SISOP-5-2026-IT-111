## 🚀 Penjelasan Implementasi Sistem

Bagian ini menjelaskan langkah demi langkah bagaimana sistem operasi ini dirakit dari nol hingga menjadi OS yang bisa digunakan untuk internetan dan menginstal aplikasi, sesuai dengan permintaan soal Modul 5.

### 1. Membuat "Jantung" Sistem Operasi (Soal 2)
Langkah pertama adalah membuat mesin utamanya. Melalui skrip `kernel.sh`, sistem akan mengunduh inti sistem operasi (Linux Kernel versi 6.1.1) dari internet, lalu merakitnya secara otomatis. Hasil rakitan ini disimpan dengan nama `bzImage` yang nantinya akan bertugas mengatur semua perangkat lunak dan perangkat keras.

### 2. Membuat OS Versi Dasar / Single-User (Soal 3)
Setelah jantungnya jadi, kita membuat "badan" sistem operasinya melalui skrip `single.sh`. Di versi dasar ini, kita membuat struktur folder standar Linux (seperti folder bin, dev, etc). 
* **Pengguna:** Di versi ini, sistem hanya mengenali satu orang penguasa mutlak, yaitu `root`. Tidak ada pengguna lain yang diizinkan masuk.
* **Hasil:** Sistem dasar ini dibungkus menjadi satu file bernama `single.gz`. Supaya laptop tidak penuh, file-file sisa pembuatannya langsung dihapus otomatis oleh skrip.

### 3. Membuat OS Versi Canggih / Multi-User (Soal 4)
Karena OS versi dasar terlalu sepi, kita menggunakan skrip `multi.sh` untuk melakukan *upgrade* menjadi OS yang bisa dipakai banyak orang sekaligus, lengkap dengan aturan kunci pintunya.
* **Papan Sambutan:** Saat pengguna berhasil masuk, layar akan menampilkan hiasan ASCII Art bertuliskan **Farewell Party** dan menyapa pengguna yang sedang *login*.
* **Penghuni Sistem:** Sistem ini sekarang punya 5 penghuni dengan kata sandinya masing-masing, yaitu `root` (root123), `henn` (henn123), `hann` (hann123), `viii` (viii123), dan `kids` (kids123).
* **Aturan Kunci Pintu (Hak Akses):**
  * **root:** Punya kunci master. Bisa masuk dan mengacak-acak ruangan siapa saja.
  * **henn:** Bisa masuk ke semua kamar penghuni lain, tapi dilarang keras masuk ke ruang rahasia milik bos (`/root`).
  * **hann:** Hanya bisa main ke kamar bawahan-bawahannya (`viii` dan `kids`).
  * **viii:** Cuma berani main ke kamar `kids`.
  * **kids:** Anak bungsu yang cuma boleh diam di kamarnya sendiri dan tidak bisa masuk ke kamar siapa-siapa.
  * Semua penghuni bebas menggunakan ruang penyimpanan umum / ruang publik (`/tmp/`).
* **Hasil:** OS versi canggih ini dibungkus dengan nama `multi.gz`.

### 4. Mencetak Kaset Instalasi / Bootable ISO (Soal 5)
Supaya OS kita bisa diputar seperti kaset, skrip `iso.sh` akan menggabungkan OS versi Dasar dan OS versi Canggih tadi ke dalam satu file siap pakai bernama `farewell.iso`. 

### 5. Tombol Pintas Emulator QEMU (Soal 6)
Untuk menyalakan OS yang sudah kita buat, disediakan "tombol remot" bernama `qemu.sh` dengan tiga pilihan cara menyala:
* Ketik `./qemu.sh --single` untuk menyalakan OS versi Dasar (langsung masuk ke `root`).
* Ketik `./qemu.sh --multi` untuk menyalakan OS versi Canggih (bisa pilih mau *login* sebagai siapa).
* Ketik `./qemu.sh --all` untuk menyalakan OS layaknya memasukkan kaset CD, nanti kita bisa memilih di layar mau menyalakan versi yang mana.

### 6. Fitur Petugas Kebersihan / Backup (Soal 7)
Karena file pembuatan OS ini ukurannya raksasa, ada skrip `./backup.sh` yang bertugas sebagai petugas kebersihan. Kalau skrip ini dijalankan, dia akan membungkus semua hasil kerja keras kita ke dalam sebuah brankas ZIP (contoh: `farewell_backup_04062026-150000.zip`). Setelah dibungkus aman, file-file mentahan yang berserakan akan disapu bersih supaya laptop tidak lemot.

### 7. Fitur Akses Internet (Soal 8)
OS buatan kita tidak dikurung sendirian. Dia sudah ditanamkan kabel jaringan virtual (IP `10.0.2.15`) yang membuatnya bisa berselancar ke internet. Ini sudah dibuktikan dengan keberhasilan OS kita memanggil satelit Google (`ping 8.8.8.8`) dan sukses mengunduh sebuah halaman web luar menggunakan perintah `wget`.

### 8. Membangun "App Store" Sendiri (Soal 9 & 10)
Sistem operasi yang bagus harus bisa menginstal aplikasi. Oleh karena itu, ditanamkan sebuah program toko aplikasi buatan kita sendiri bernama **`party`**. 
* Kita sudah membuktikan bahwa toko aplikasi ini berfungsi dengan baik dengan cara mengetikkan perintah `party install fuse`. 
* Perintah itu sukses mengunduh dan memasang aplikasi FUSE ke dalam sistem. Terakhir, kita berhasil membuka aplikasi tersebut dengan mengetik `simple_fuse` dan aplikasinya berjalan dengan lancar.
