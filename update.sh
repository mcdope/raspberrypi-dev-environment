#!/bin/bash

IMAGEFILE="arch-pimirror.img"

echo "[INFO] Killing some 'known to be assholes' processes that might interfer..."
sudo killall tracker-miner-fs
sudo killall tracker-miner-apps
sudo killall tracker-store
sudo killall dropbox

# Rename image if exists
if [ -f "$IMAGEFILE" ]; then
    if [ -f "$IMAGEFILE.old" ]; then
        echo -n "[INFO] removing image backup created on last update.sh run"
        
        if rm $IMAGEFILE.old ; then
            echo " ... success!"
        else
            echo " ... FAILED!"
            exit 1
        fi
    fi

    echo -n "[INFO] creating image backup from last update.sh run"
    
    if mv $IMAGEFILE $IMAGEFILE.old ; then
            echo " ... success!"
    else
        echo " ... FAILED!"
        exit 1
    fi

    echo
fi

# Check if other loop device is active, abort in case
if [ -b "/dev/mapper/loop0p1" ]; then
    echo "[ERROR] another loop device is active, please remove it before running update.sh again!"
    exit 1
fi

if [ -d "arch_bootpart" ]; then
    echo -n "[INFO] removing previous arch_bootpart"
    
    if rm -rf arch_bootpart ; then
        echo " ... success!"
    else
        echo " ... FAILED!"
        exit 1
    fi
fi

# Create "HDD" image
echo -n "[INFO] creating HDD image..."
if dd status=none if=/dev/zero bs=524288 count=16384 > $IMAGEFILE ; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

echo "[INFO] Partioning image..."
echo
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
echo

if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi


# Download rootfs
echo -n "[INFO] Downloading archlinux-arm rootfs..."
echo
echo
wget http://dk.mirror.archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi
echo
echo

# Mount image as loopback device and format FS(es)
echo -n "[INFO] Mounting image as loopdevice..."
sudo kpartx -a $IMAGEFILE
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

if [ -b "/dev/mapper/loop0p1" ]; then
    echo "[DEBUG] loop0p1 found, we should be able to continue"
else
    echo "[DEBUG] Big WTF - loop0p1 not found, but kpartx returned no error..."
    echo "[DEBUG] kpartx -l"
    kpartx -l $IMAGEFILE
    echo "[DEBUG] ls /dev/mapper"
    ls /dev/mapper
    echo "[ERROR] Big-fat-what-da-faq - loop0p1 not found but kpartx returned success?! k thx bye..."
fi

echo
echo "[INFO] Formatting FAT /boot..."
sudo mkfs.vfat /dev/mapper/loop0p1
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

echo "[INFO] Formatting ext4 /..."
sudo mkfs.ext4 /dev/mapper/loop0p2
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi
echo
echo

# Create mountpoints and mount partitions
echo -n "[INFO] Mounting image partitions..."
mkdir boot
mkdir root
sudo mount /dev/mapper/loop0p1 boot
if [ $? -eq 0 ]; then
    echo -n " ... boot success!"
else
    echo " ... boot FAILED!"
    exit 1
fi

sudo mount /dev/mapper/loop0p2 root
if [ $? -eq 0 ]; then
    echo " ... root success!"
else
    echo " ... root FAILED!"
    exit 1
fi

# Extract rootfs
echo -n "[INFO] Extracting rootfs..."
sudo bsdtar -xpf ArchLinuxARM-rpi-3-latest.tar.gz -C root
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

sync

# Move boot files to bootpart (part 1)
echo -n "[INFO] Moving root/boot to /boot..."
sudo mv root/boot/* boot
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

sync

# Copy files we need to boot QEMU
echo -n "[INFO] Copying /boot for qemu..."
mkdir arch_bootpart
cp -R boot/* arch_bootpart/
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

# Adjust fstab for qemu
echo -n "[INFO] Adjusting /etc/fstab for qemu..."
sudo sed -i 's/mmcblk0p/vda/g' root/etc/fstab
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

# Enable password auth for ssh on root for copy id
echo -n "[INFO] Enable password login for root over ssh..."
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' root/etc/ssh/sshd_config
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi


# Unmount everything
echo "[INFO] Syncing fs'es before unmounting..."
sync

echo "[INFO] Unmounting image partitions..."
sudo umount -dv boot
if [ $? -eq 0 ]; then
    echo " ... boot success!"
else
    echo " ... boot FAILED!"
    exit 1
fi

sleep 1

sudo umount -dv root
if [ $? -eq 0 ]; then
    echo " ... root success!"
else
    echo " ... root FAILED!"

    # Some special case logging to find which motherfucker process needs to be nuked from orbit
    echo "[DEBUG] ps -aux"
    ps -aux
    echo "[DEBUG] lsof +D 'root'"
    lsof +D 'root'

    exit 1
fi

sleep 1
echo -n "[INFO] Unmounting image loopdevice..."
sudo kpartx -d $IMAGEFILE
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

sleep 1

# Cleanup
echo -n "[INFO] Cleaning up..."
rm -rf boot
if [ $? -eq 0 ]; then
    echo -n " ... boot success!"
else
    echo " ... boot FAILED!"
    exit 1
fi

rm -rf root
if [ $? -eq 0 ]; then
    echo -n " ... root success!"
else
    echo " ... root FAILED!"
    exit 1
fi

rm ArchLinuxARM-rpi-3-latest.tar.gz
if [ $? -eq 0 ]; then
    echo " ... rootfs success!"
else
    echo " ... FAILED!"
    exit 1
fi

echo
echo "Image created, initializing now..."
echo "(this will take a while, VM will boot for it and be shutdown again when finished)"
echo
echo
echo
sleep 5

echo "[DEBUG] Calling init_arch.sh..."
./init_arch.sh
echo "[DEBUG] init_arch.sh is done. We should have a bootable image now."
stat $IMAGEFILE

echo
echo "... VM ready, done!"
echo
echo "To start the VM run \"boot.sh\"."
echo "After booting you can connect by running \"ssh -p 5022 alarm@localhost\", or if you want to be root \"ssh -p 5022 root@localhost\""

