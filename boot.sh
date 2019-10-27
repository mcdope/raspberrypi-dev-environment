#!/bin/bash
CPUCORES_TOTAL=`getconf _NPROCESSORS_ONLN`
CPUCORES_QEMU=$((CPUCORES_TOTAL/2)) # we only use half of all cores to prevent stalling the host
KEYBOARD_LAYOUT=`setxkbmap -query | grep layout | cut -d' ' -f6`

echo "Will start VM now, but a quick warning ahead: CTRL-C will NOT be send to VM but instead will close the VM without shutdown!"
sleep 5

x-terminal-emulator -e "qemu-system-aarch64 \
  -kernel arch_bootpart/Image.gz \
  -initrd arch_bootpart/initramfs-linux.img \
  -m 1024 -M virt \
  -cpu cortex-a53 \
  -serial stdio \
  -append \"rw root=/dev/vda2 console=ttyAMA0 loglevel=8 rootwait fsck.repair=yes memtest=1 audit=0\" \
  -hda arch-pimirror.img \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -device virtio-net-device,netdev=net0 \
  -no-reboot
  -accel kvm,thread=multi
  -smp cpus=$CPUCORES_QEMU
  -k $KEYBOARD_LAYOUT
  -name raspberrypi-dev-environment
  -no-quit"