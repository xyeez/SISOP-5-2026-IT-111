#!/bin/bash

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
