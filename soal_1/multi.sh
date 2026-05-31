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
