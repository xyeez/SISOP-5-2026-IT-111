#!/bin/bash

# 1. Dapatkan waktu sekarang dengan format DDMMYYYY-HHMMSS
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_NAME="farewell_backup_${TIMESTAMP}.zip"

echo "[backup] Memulai proses pengarsipan..."

# 2. Pastikan folder osboot ada
mkdir -p osboot

# 3. Kompres skrip-skrip penting kita ke dalam file .zip di folder osboot
# (Pastikan kamu sudah menginstal zip dengan: sudo apt install zip)
zip -r "osboot/${BACKUP_NAME}" multi.sh qemu.sh iso.sh 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[backup] SUCCESS: Berkas berhasil diarsip ke osboot/${BACKUP_NAME}"
    
    # 4. Bersihkan folder mentahan rootfs agar hemat memori (sesuai Soal No. 7)
    echo "[backup] Membersihkan folder mentahan rootfs_multi..."
    rm -rf rootfs_multi
    echo "[backup] Pembersihan selesai! Ruang penyimpanan kembali lega."
else
    echo "[backup] ERROR: Gagal membuat backup. Coba jalankan 'sudo apt install zip' terlebih dahulu."
fi

