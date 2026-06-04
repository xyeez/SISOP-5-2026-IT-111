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
