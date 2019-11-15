#!/bin/bash

TARGETFILE="arch-pimirror.sdcard.img"

echo "Killing some 'known to be assholes' processes that might interfer..."
sudo killall tracker-miner-fs
sudo killall tracker-miner-apps
sudo killall tracker-store
sudo killall dropbox

echo "Creating copy of image before modifying..."
cp arch-pimirror.img $TARGETFILE

echo "Mounting image as loopdevice..."
sudo kpartx -a $TARGETFILE

echo "Mounting image partitions..."
mkdir boot
mkdir root
sudo mount /dev/mapper/loop0p1 boot
sudo mount /dev/mapper/loop0p2 root

echo "Adjusting /etc/fstab for sdcard..."
sudo sed -i 's/vda/mmcblk0p/g' root/etc/fstab

echo "Syncing fs'es before unmounting..."
sync

echo "Unmounting image partitions..."
sudo umount -dv boot
sleep 1
sudo killall tracker-miner-fs # tends to get restarted and will block umount'ing
sudo umount -dv root
sleep 1
echo "Unmounting image loopdevice..."
sudo kpartx -d $TARGETFILE
sleep 1

# Cleanup
echo "Cleaning up..."
rm -rf boot
rm -rf root

echo
echo "Done!"
echo "Your SD image is available as $TARGETFILE and can be written with dd or similiar."