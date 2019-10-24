#!/bin/bash
x-terminal-emulator -e "qemu-system-aarch64 \
  -kernel arch_bootpart/Image.gz \
  -initrd arch_bootpart/initramfs-linux.img \
  -m 1024 -M virt \
  -cpu cortex-a53 \
  -serial stdio \
  -append \"rw root=/dev/vda2 console=ttyAMA0 loglevel=8 rootwait fsck.repair=yes memtest=1\" \
  -hda arch-pimirror.img \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -device virtio-net-device,netdev=net0 \
  -no-reboot"