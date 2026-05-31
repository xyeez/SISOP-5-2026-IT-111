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
