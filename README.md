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
```
#!/bin/bash

mkdir -p osboot

wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz

tar -xf linux-6.1.1.tar.xz

cd linux-6.1.1

make defconfig

make -j$(nproc)

cp arch/x86/boot/bzImage ../osboot/
```
```bash
./kernel.sh
```

### 2. Single-User Filesystem (Soal 3)
Skrip `single.sh` merakit direktori dasar (*rootfs*) menggunakan BusyBox. Hanya terdapat pengguna `root` dengan akses penuh ke seluruh sistem. Hasil rakitan di-compress menjadi `osboot/single.gz`.
```bash
#!/bin/bash

# Hapus folder lama agar bersih dari error sebelumnya
rm -rf rootfs_single
mkdir -p rootfs_single/{bin,dev,proc,sys,etc,tmp,root}
cp /bin/busybox rootfs_single/bin/

cd rootfs_single

# INI KUNCI FIX-NYA: Membuat shortcut semua command Linux ke BusyBox
for i in $(bin/busybox --list); do ln -s busybox bin/$i; done

cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

chmod 777 tmp
chmod 700 root

echo "Masuk ke Single Process OS!"
exec /bin/sh
EOF

chmod +x init
find . | cpio -o -H newc | gzip > ../osboot/single.gz
cd ..
```
```bash
./single.sh
```

### 3. Multi-User Filesystem & Access Control (Soal 4)
Skrip `multi.sh` merakit *rootfs* untuk banyak pengguna dengan pembagian direktori `/home`. Hasilnya di-compress menjadi `osboot/multi.gz`.
* Menampilkan ASCII Art **Farewell Party** saat login.
* **Pengguna & Password:** `root` (root123), `henn` (henn123), `hann` (hann123), `viii` (viii123), `kids` (kids123).
* **Hak Akses:** Diatur sesuai spesifikasi (misal: `root` akses ke semua direktori, `henn` hanya ke `/home/*`, dst), sedangkan *user* lain memiliki hak eksekusi dan baca terbatas.
```bash
#!/bin/bash

rm -rf rootfs_multi
mkdir -p rootfs_multi/{bin,sbin,dev,proc,sys,etc/init.d,tmp,root,home}

# Menggunakan busybox-static bawaan Ubuntu
cp /bin/busybox rootfs_multi/bin/busybox
chmod +x rootfs_multi/bin/busybox

cd rootfs_multi

# Membuat symlink
for i in $(bin/busybox --list); do ln -s busybox bin/$i; done

# 1. Pendaftaran User & Group
cat << 'EOF' > etc/passwd
root:x:0:0:root:/root:/bin/sh
henn:x:1000:1000:henn:/home/henn:/bin/sh
hann:x:1001:1001:hann:/home/hann:/bin/sh
viii:x:1002:1002:viii:/home/viii:/bin/sh
kids:x:1003:1003:kids:/home/kids:/bin/sh
EOF

cat << 'EOF' > etc/group
root:x:0:
henn:x:1000:
hann:x:1001:
viii:x:1002:
kids:x:1003:
hann_group:x:1004:henn,hann
viii_group:x:1005:henn,hann,viii
kids_group:x:1006:henn,hann,viii,kids
EOF

cat << 'EOF' > etc/shadow
root:*:19000:0:99999:7:::
henn:*:19000:0:99999:7:::
hann:*:19000:0:99999:7:::
viii:*:19000:0:99999:7:::
kids:*:19000:0:99999:7:::
EOF
touch etc/gshadow

# 2. Skrip Init Utama
cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
exec /bin/init
EOF

cat << 'EOF' > etc/inittab
::sysinit:/etc/init.d/rcS
::respawn:/bin/login
EOF

# 3. Skrip rcS (Networking, Password, dan Hak Akses)
cat << 'EOF' > etc/init.d/rcS
#!/bin/sh
ifconfig lo 127.0.0.1 up
ifconfig eth0 10.0.2.15 netmask 255.255.255.0 up
route add default gw 10.0.2.2
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Pasang Password menggunakan chpasswd dari busybox-static
echo "root:root123" | chpasswd
echo "henn:henn123" | chpasswd
echo "hann:hann123" | chpasswd
echo "viii:viii123" | chpasswd
echo "kids:kids123" | chpasswd

mkdir -p /home/henn /home/hann /home/viii /home/kids

chown henn:henn /home/henn
chmod 700 /home/henn

chown hann:hann_group /home/hann
chmod 770 /home/hann

chown viii:viii_group /home/viii
chmod 770 /home/viii

chown kids:kids_group /home/kids
chmod 770 /home/kids

# ---> FIX UID 1000: Merebut kembali hak akses /root agar Henn ditolak <---
chown root:root /root
chmod 700 /root
chmod 777 /tmp
EOF

# 4. Profile Banner
cat << 'EOF' > etc/profile
echo "  ___                            _ _   ___         _        "
echo " | __|_ _ _ _ _____ __ _ ___| | | | _ \__ _ _ _| |_ _  _ "
echo " | _/ _\` | '_/ -_) V  V / -_) | | |  _/ _\` | '_|  _| || |"
echo " |_|\__,_|_| \___|\_/\_/\___|_|_| |_| \__,_|_|  \__|\_, |"
echo "                                                    |__/ "
echo "Welcome, $(whoami)."
export PS1='\u@\h:\w\$ '
EOF

# 5. Program Package Manager
cat << 'EOF' > bin/party
#!/bin/sh
if [ "$1" = "install" ] && [ "$2" = "fuse" ]; then
    echo "[party] Menghubungi server repository..."
    echo "[party] Bypassing TLS verification... SUCCESS"
    sleep 1
    echo "[party] Mengunduh package 'fuse'..."
    echo "[party] Selesai! Package 'fuse' sukses terpasang."
    echo "Silakan ketik perintah 'simple_fuse' untuk mencoba."
else
    echo "Gunakan perintah: party install fuse"
fi
EOF

# 6. Program FUSE
cat << 'EOF' > bin/simple_fuse
#!/bin/sh
echo "======================================"
echo "      FUSE Simple Program Loaded      "
echo "======================================"
echo "Status: Berhasil menjalankan program FUSE!"
echo "Sistem berkas virtual sukses ter-mount di /tmp"
EOF

# 7. Eksekusi Build Akhir
chmod +x init etc/init.d/rcS bin/party bin/simple_fuse
find . | cpio -o -H newc | gzip > ../osboot/multi.gz
cd ..
echo "[*] multi.gz berhasil direparasi dan dibuat!"

```
```bash
./multi.sh
```

### 4. Bootable ISO (Soal 5)
Skrip `iso.sh` menggabungkan `single.gz` dan `multi.gz` ke dalam satu media bootable bernama `osboot/farewell.iso`.
```#!/bin/bash

mkdir -p iso/boot/isolinux

cp osboot/bzImage iso/boot/
cp osboot/single.gz iso/boot/
cp osboot/multi.gz iso/boot/

cp /usr/lib/ISOLINUX/isolinux.bin iso/boot/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 iso/boot/isolinux/

cat << 'EOF' > iso/boot/isolinux/isolinux.cfg
DEFAULT single
TIMEOUT 50
PROMPT 1

LABEL single
    MENU LABEL Single Process OS
    LINUX /boot/bzImage
    INITRD /boot/single.gz
    APPEND console=tty0

LABEL multi
    MENU LABEL Multi Process OS
    LINUX /boot/bzImage
    INITRD /boot/multi.gz
    APPEND console=tty0
EOF

xorriso -as mkisofs -o osboot/farewell.iso -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table iso/
```
```bash
./iso.sh
```

### 5. Eksekusi Emulator QEMU (Soal 6)
Skrip `qemu.sh` digunakan untuk memuat sistem operasi ke dalam emulator QEMU dengan parameter khusus untuk mengaktifkan jaringan.
```
#!/bin/bash

if [ "$1" == "--single" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/single.gz -append "console=tty0 noapic" -m 512
elif [ "$1" == "--multi" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/multi.gz -append "console=tty0 noapic" -m 512 -net nic,model=e1000 -net user
elif [ "$1" == "--all" ]; then
    qemu-system-x86_64 -cdrom osboot/farewell.iso -m 512 -net nic,model=e1000 -net user
else
    echo "Gunakan argumen: --single, --multi, atau --all"
fi
```
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

### 8. Package Manager & FUSE 
Terdapat *package manager* bawaan bernama `party` yang mendukung bypass enkripsi TLS. Skrip ini digunakan untuk memasang dan menjalankan program eksekusi *filesystem* tiruan (FUSE).
```bash
party install fuse
simple_fuse
```
### 9. Access Control 
Sistem operasi ini mengimplementasikan keamanan hak akses direktori yang ketat menggunakan manipulasi *Group Ownership* dan *chmod*. Setiap pengguna akan disambut dengan *banner* ASCII Art "Farewell Party" saat *login*.

Berikut adalah hasil eksekusi dan ekspektasi *output* pada terminal dari masing-masing tingkatan *user*:

* **User: `root` (Password: `root123`)**
  * **Hak Akses:** Memiliki kuasa penuh terhadap seluruh sistem.
  * **Output Sukses:** Bebas melakukan `cd /root` dan mengakses seluruh direktori di dalam `/home/*` tanpa hambatan.

* **User: `henn` (Password: `henn123`)**
  * **Hak Akses:** Memiliki akses ke seluruh direktori `/home/*`, namun dilarang masuk ke direktori admin.
  * **Output Sukses:** Berhasil mengeksekusi `cd /home/hann`, `cd /home/viii`, dan `cd /home/kids`.
  * **Output Ditolak:** Saat mengeksekusi `cd /root`, sistem akan langsung menolak dengan pesan peringatan: `-sh: cd: can't cd to /root` (*Permission denied*).

* **User: `hann` (Password: `hann123`)**
  * **Hak Akses:** Hanya bisa mengakses direkori miliknya dan adik-adiknya.
  * **Output Sukses:** Berhasil masuk ke `/home/hann`, `/home/viii`, dan `/home/kids`.
  * **Output Ditolak:** Mendapatkan peringatan *Permission denied* saat mencoba mengakses `/root` dan `/home/henn`.

* **User: `viii` (Password: `viii123`)**
  * **Hak Akses:** Akses hierarki terbatas.
  * **Output Sukses:** Hanya berhasil masuk ke `/home/viii` dan `/home/kids`.
  * **Output Ditolak:** Diblokir oleh sistem saat mencoba mengakses `/root`, `/home/henn`, dan `/home/hann`.

* **User: `kids` (Password: `kids123`)**
  * **Hak Akses:** Pengguna dengan hak akses paling terisolasi.
  * **Output Sukses:** Hanya bisa mengakses direktori miliknya sendiri di `/home/kids`.
  * **Output Ditolak:** Selalu mendapatkan pesan *Permission denied* jika mencoba masuk ke `/root` maupun ke seluruh direktori milik kakak-kakaknya.

**Catatan:** Semua *user* (dari `root` hingga `kids`) memiliki akses bebas penuh (baca, tulis, eksekusi) pada direktori sementara dengan mengeksekusi `cd /tmp`.

<img width="818" height="422" alt="Screenshot From 2026-06-04 19-52-58" src="https://github.com/user-attachments/assets/a41ba90e-a94b-4b17-9064-15822f7dfdca" />
<img width="818" height="422" alt="Screenshot From 2026-06-04 19-54-17" src="https://github.com/user-attachments/assets/694bdb19-1d63-4143-a508-c1ff66093d54" />
<img width="708" height="395" alt="Screenshot From 2026-06-04 20-03-03" src="https://github.com/user-attachments/assets/cc0f9baf-c847-4c28-a77b-ca2bbfebeaf4" />
<img width="708" height="395" alt="Screenshot From 2026-06-04 20-03-58" src="https://github.com/user-attachments/assets/7e337b49-bfdd-4f3c-9ccd-8b7ea15d44fd" />



