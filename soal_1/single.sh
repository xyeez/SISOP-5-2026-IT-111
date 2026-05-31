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
