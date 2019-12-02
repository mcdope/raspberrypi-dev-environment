#!/bin/bash

IMAGEFILE="arch-pimirror.img"
LOGFILE="log.out"

# Serious bash kungfu to log everything, see https://serverfault.com/a/103569
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LOGFILE 2>&1
LOGGING=1
# echo' to >&3 if you wanna display shit - everything else below will go to the file 'log.out':

echo "[INFO] Killing some 'known to be assholes' processes that might interfer..." >&3
echo "[INFO] Killing some 'known to be assholes' processes that might interfer..."
sudo killall tracker-miner-fs
sudo killall tracker-miner-apps
sudo killall tracker-store
sudo killall dropbox

# Rename image if exists
if [ -f "$IMAGEFILE" ]; then
    if [ -f "$IMAGEFILE.old" ]; then
        echo "[INFO] removing image backup created on last update.sh run"
        echo -n "[INFO] removing image backup created on last update.sh run" >&3
        
        if rm $IMAGEFILE.old ; then
            echo " ... success!" >&3
        else
            echo " ... FAILED!" >&3
            exit 1
        fi
    fi

    echo "[INFO] creating image backup from last update.sh run"
    echo -n "[INFO] creating image backup from last update.sh run" >&3
    
    if mv $IMAGEFILE $IMAGEFILE.old ; then
            echo " ... success!" >&3
    else
        echo " ... FAILED!" >&3
        exit 1
    fi

    echo >&3
fi

# Check if other loop device is active, abort in case
if [ -f "/dev/mapper/loop0p1" ]; then
    echo "[ERROR] another loop device is active, please remove it before running update.sh again!"
    echo "[ERROR] another loop device is active, please remove it before running update.sh again!" >&3
    exit 1
fi

if [ -d "arch_bootpart" ]; then
    echo "[INFO] removing previous arch_bootpart"
    echo -n "[INFO] removing previous arch_bootpart" >&3
    
    if rm -rf arch_bootpart ; then
        echo " ... success!" >&3
    else
        echo " ... FAILED!" >&3
        exit 1
    fi
fi

# Create "HDD" image
echo "[INFO] creating HDD image..."
echo -n "[INFO] creating HDD image..." >&3
if dd status=none if=/dev/zero bs=524288 count=16384 > $IMAGEFILE ; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

echo "[INFO] Partioning image..."
echo -n "[INFO] Partioning image..." >&3
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

if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi


# Download rootfs
echo "[INFO] Downloading archlinux-arm rootfs..."
echo -n "[INFO] Downloading archlinux-arm rootfs..." >&3
echo
echo
wget http://dk.mirror.archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi
echo
echo

# Mount image as loopback device and format FS(es)
echo "[INFO] Mounting image as loopdevice..."
echo -n "[INFO] Mounting image as loopdevice..." >&3
sudo kpartx -a $IMAGEFILE
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

echo
echo "[INFO] Formatting FAT /boot..."
echo -n "[INFO] Formatting FAT /boot..." >&3
sudo mkfs.vfat /dev/mapper/loop0p1 > /dev/null
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

echo "[INFO] Formatting ext4 /..."
echo -n "[INFO] Formatting ext4 /..." >&3
sudo mkfs.ext4 /dev/mapper/loop0p2 > /dev/null
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi
echo
echo

# Create mountpoints and mount partitions
echo "[INFO] Mounting image partitions..."
echo -n "[INFO] Mounting image partitions..." >&3
mkdir boot
mkdir root
sudo mount /dev/mapper/loop0p1 boot
if [ $? -eq 0 ]; then
    echo -n " ... boot success!" >&3
else
    echo " ... boot FAILED!" >&3
    exit 1
fi

sudo mount /dev/mapper/loop0p2 root
if [ $? -eq 0 ]; then
    echo " ... root success!" >&3
else
    echo " ... root FAILED!" >&3
    exit 1
fi

# Extract rootfs
echo "[INFO] Extracting rootfs..."
echo -n "[INFO] Extracting rootfs..." >&3
sudo bsdtar -xpf ArchLinuxARM-rpi-3-latest.tar.gz -C root
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

sync

# Move boot files to bootpart (part 1)
echo "[INFO] Moving root/boot to /boot..."
echo -n "[INFO] Moving root/boot to /boot..." >&3
sudo mv root/boot/* boot
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

sync

# Copy files we need to boot QEMU
echo "[INFO] Copying /boot for qemu..."
echo -n "[INFO] Copying /boot for qemu..." >&3
mkdir arch_bootpart
cp -R boot/* arch_bootpart/
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

# Adjust fstab for qemu
echo "[INFO] Adjusting /etc/fstab for qemu..."
echo -n "[INFO] Adjusting /etc/fstab for qemu..." >&3
sudo sed -i 's/mmcblk0p/vda/g' root/etc/fstab
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

# Enable password auth for ssh on root for copy id
echo "[INFO] Enable password login for root over ssh..."
echo -n "[INFO] Enable password login for root over ssh..." >&3
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' root/etc/ssh/sshd_config
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi


# Unmount everything
echo "[INFO] Syncing fs'es before unmounting..."
echo "[INFO] Syncing fs'es before unmounting..." >&3
sync

echo "[INFO] Unmounting image partitions..."
echo -n "[INFO] Unmounting image partitions..." >&3
sudo umount -dv boot
if [ $? -eq 0 ]; then
    echo -n " ... boot success!" >&3
else
    echo " ... boot FAILED!" >&3
    exit 1
fi

sleep 1

sudo killall tracker-miner-fs # tends to get restarted and will block umount'ing

sudo umount -dv root
if [ $? -eq 0 ]; then
    echo " ... root success!" >&3
else
    echo " ... root FAILED!" >&3

    # Some special case logging to find which motherfucker process needs to be nuked from orbit
    echo "[DEBUG] ps -aux"
    ps -aux
    echo "[DEBUG] lsof +D 'root'"
    lsof +D 'root'

    exit 1
fi

sleep 1
echo "[INFO] Unmounting image loopdevice..."
echo -n "[INFO] Unmounting image loopdevice..." >&3
sudo kpartx -d $IMAGEFILE
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

sleep 1

# Cleanup
echo "[INFO] Cleaning up..."
echo -n "[INFO] Cleaning up..." >&3
rm -rf boot
if [ $? -eq 0 ]; then
    echo -n " ... boot success!" >&3
else
    echo " ... boot FAILED!" >&3
    exit 1
fi

rm -rf root
if [ $? -eq 0 ]; then
    echo -n " ... root success!" >&3
else
    echo " ... root FAILED!" >&3
    exit 1
fi

rm ArchLinuxARM-rpi-3-latest.tar.gz
if [ $? -eq 0 ]; then
    echo " ... rootfs success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

echo >&3
echo "Image created, initializing now..." >&3
echo "(this will take a while, VM will boot for it and be shutdown again when finished)" >&3
echo "Notice: all output will be logged into $LOGFILE and NOT shown, if you want to watch it" >&3
echo "        open a new terminal and tail -f it." >&3
echo >&3
echo >&3
echo >&3
sleep 5

echo "[DEBUG] Calling init_arch.sh..."
./init_arch.sh
echo "[DEBUG] init_arch.sh is done. We should have a bootable image now."
stat $IMAGEFILE

echo >&3
echo "... VM ready, done!" >&3
echo >&3
echo "To start the VM run \"boot.sh\"." >&3
echo "After booting you can connect by running \"ssh -p 5022 alarm@localhost\", or if you want to be root \"ssh -p 5022 root@localhost\"" >&3

