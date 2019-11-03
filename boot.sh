#!/bin/bash

echo
echo 'Reminder: you need to run ./netbridge_create.sh before this!'
echo "You have 10secs to CTRL+C in case you haven't yet"
echo
sleep 10

CPUCORES=`getconf _NPROCESSORS_ONLN`
KEYBOARD_LAYOUT=`setxkbmap -query | grep layout | cut -d' ' -f6 | cut -d',' -f1`

echo "WARNING: You could login in the serial terminal (the one with boot messages) that opens, but don't dare to press CTRL+C!"
echo " (it would terminate the VM without proper shutdown, expect your VM to break...)"
echo
echo "For that reason I highly recommend to login in the graphical window (titled 'QEMU - raspberrypi-dev-environment')!"
echo

sleep 5

x-terminal-emulator -e "qemu-system-aarch64 \
  -kernel arch_bootpart/Image.gz \
  -initrd arch_bootpart/initramfs-linux.img \
  -append \"rw root=/dev/vda2 console=ttyAMA0 loglevel=8 rootwait fsck.repair=yes memtest=1 audit=0 CONFIG_DRM=y CONFIG_DRM_VIRTIO_GPU=y\" \
  -m 1024 -M virt \
  -cpu cortex-a53 \
  -accel tcg,thread=multi \
  -smp cpus=$CPUCORES \
  -k $KEYBOARD_LAYOUT \
  -name raspberrypi-dev-environment \
  -serial stdio \
  -drive file=arch-pimirror.img,if=virtio,cache=none,aio=threads \
  -netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-device,netdev=mynet0,mac=52:55:00:d1:55:01 \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -device virtio-net-device,netdev=net0 \
  -device virtio-gpu-pci \
  -vga std \
  -device usb-ehci \
  -device usb-tablet \
  -device usb-kbd \
  -show-cursor \
  -no-reboot \
  -no-quit"