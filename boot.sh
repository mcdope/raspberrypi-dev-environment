#!/bin/bash
CPUCORES=`getconf _NPROCESSORS_ONLN`
KEYBOARD_LAYOUT=`setxkbmap -query | grep layout | cut -d' ' -f6`

echo "WARNING: You can login in the serial terminal that opens, but don't dare to press CTRL+C!"
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
  -smp cpus=$CPUCORES \
  -k $KEYBOARD_LAYOUT \
  -name raspberrypi-dev-environment \
  -serial stdio \
  -drive file=arch-pimirror.img,if=virtio,cache=none \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -device virtio-net-device,netdev=net0 \
  -device virtio-gpu-pci \
  -no-reboot \
  -no-quit; sleep 30"