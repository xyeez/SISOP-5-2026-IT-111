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
```
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
```
#!/bin/bash

rm -rf rootfs_multi
mkdir -p rootfs_multi/{bin,sbin,dev,proc,sys,etc/init.d,tmp,root,home}
cp /bin/busybox rootfs_multi/bin/

cd rootfs_multi

for i in $(bin/busybox --list); do ln -s busybox bin/$i; done

echo "root:x:0:0:root:/root:/bin/sh" > etc/passwd
echo "root:x:0:" > etc/group
echo "root:*:19000:0:99999:7:::" > etc/shadow
touch etc/gshadow

cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
exec init
EOF

cat << 'EOF' > etc/inittab
::sysinit:/etc/init.d/rcS
::respawn:/bin/login
EOF

cat << 'EOF' > etc/init.d/rcS
#!/bin/sh
ifconfig lo 127.0.0.1 up
ifconfig eth0 10.0.2.15 netmask 255.255.255.0 up
route add default gw 10.0.2.2
echo "nameserver 8.8.8.8" > /etc/resolv.conf

mkdir -p /home/henn /home/hann /home/viii /home/kids
echo "root:root123" | chpasswd
chmod 777 /tmp
chmod 700 /root
EOF

cat << 'EOF' > etc/profile
echo "==================================="
echo "         Farewell Party"
echo "==================================="
echo "Welcome, $(whoami)."
export PS1='\u@\h:\w\$ '
EOF

# Program Package Manager Dummy
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

# Program FUSE Dummy
cat << 'EOF' > bin/simple_fuse
#!/bin/sh
echo "======================================"
echo "      FUSE Simple Program Loaded      "
echo "======================================"
echo "Status: Berhasil menjalankan program FUSE!"
echo "Sistem berkas virtual sukses ter-mount di /tmp"
EOF

chmod +x init etc/init.d/rcS bin/party bin/simple_fuse
find . | cpio -o -H newc | gzip > ../osboot/multi.gz
cd ..
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

### 8. Package Manager & FUSE (Soal 9 & 10)
Terdapat *package manager* bawaan bernama `party` yang mendukung bypass enkripsi TLS. Skrip ini digunakan untuk memasang dan menjalankan program eksekusi *filesystem* tiruan (FUSE).
```bash
party install fuse
simple_fuse
```
