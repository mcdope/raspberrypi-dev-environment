#!/bin/bash

# Update repo and device/kernel submodule
# git fetch
# git pull --recurse-submodules

echo
echo 'Reminder: you need to run ./netbridge_create.sh before this!'
echo "You have 10secs to CTRL+C in case you haven't yet"
echo
sleep 10

IMAGEFILE="arch-pimirror.img"

# Rename image if exists
if [ -f "$IMAGEFILE" ]; then
    if [ -f "$IMAGEFILE.old" ]; then
    echo "Info: removed image backup created on last update.sh run."
        rm $IMAGEFILE.old
    fi

    echo "Info: created image backup from last update.sh run."
    mv $IMAGEFILE $IMAGEFILE.old
    echo
fi

# Check if other loop device is active, abort in case
if [ -f "/dev/mapper/loop0p1" ]; then
    echo "Error: another loop device is active, please remove it before running update.sh again!"
fi

if [ -d "arch_bootpart" ]; then
    rm -rf arch_bootpart
    echo "Info: removed previous arch_bootpart"
fi

# Create "HDD" image
echo "Creating HDD image..."
dd status=none if=/dev/zero bs=524288 count=16384 > $IMAGEFILE 

echo "Partioning image..."
# Partition image (see https://superuser.com/a/332322/462629)
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo 1 # Partition number
echo   # First sector (Accept default: 1)
echo +200M  # Last sector (Accept default: varies)
echo t # Set type
echo c # W95 FAT32 (LBA)
echo n # Add a new partition
echo p # Primary partition
echo 2 # Partition number
echo   # First sector (Accept default: wherever part1 ends)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | fdisk $IMAGEFILE

clear
# Download rootfs
echo "Downloading archlinux-arm rootfs..."
echo
echo
wget http://dk.mirror.archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz
echo
echo

# Mount image as loopback device and format FS(es)
echo "Mounting image as loopdevice..."
sudo kpartx -a $IMAGEFILE
echo
echo "Formatting FAT /boot..."
sudo mkfs.vfat /dev/mapper/loop0p1 > /dev/null
echo "Formatting ext4 /..."
sudo mkfs.ext4 /dev/mapper/loop0p2 > /dev/null
echo
echo

# Create mountpoints and mount partitions
echo "Mounting image partitions..."
mkdir boot
mkdir root
sudo mount /dev/mapper/loop0p1 boot
sudo mount /dev/mapper/loop0p2 root

# Extract rootfs
echo "Extracting rootfs..."
sudo bsdtar -xpf ArchLinuxARM-rpi-3-latest.tar.gz -C root
sync

# Move boot files to bootpart (part 1)
echo "Moving root/boot to /boot..."
sudo mv root/boot/* boot
sync

# Copy files we need to boot QEMU
echo "Copying /boot for qemu..."
mkdir arch_bootpart
cp -R boot/* arch_bootpart/

# Adjust fstab for qemu
echo "Adjusting /etc/fstab for qemu..."
sudo sed -i 's/mmcblk0p/vda/g' root/etc/fstab

# Enable password auth for ssh on root for copy id
echo "Enable password login for root over ssh..."
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' root/etc/ssh/sshd_config


# Unmount everything
echo "Syncing fs'es before unmounting..."
sync

echo "Unmounting image partitions..."
sudo umount boot
sleep 1
sudo umount root
sleep 1
echo "Unmounting image loopdevice..."
sudo kpartx -d $IMAGEFILE
sleep 1

# Cleanup
echo "Cleaning up..."
rm -rf boot
rm -rf root
rm ArchLinuxARM-rpi-3-latest.tar.gz

echo
echo "Image created, initializing now..."
echo "(this will take a while, VM will boot for it and be shutdown again when finished)"
echo
echo
echo
sleep 5

./init_arch.sh

echo
echo "... VM ready, done!"
echo
echo "To start the VM run \"boot.sh\"."
echo "After booting you can connect by running \"ssh -p 5022 alarm@localhost\", or if you want to be root \"ssh -p 5022 root@localhost\""

