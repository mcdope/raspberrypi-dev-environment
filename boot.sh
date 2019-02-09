#!/bin/bash
./environment-notice.sh

qemu-system-arm \
  -M versatilepb \
  -cpu arm1176 \
  -m 256 \
  -hda ./raspbian-stretch-lite.img \
  -net nic \
  -net user,hostfwd=tcp::5022-:22 \
  -dtb ./raspbian_bootpart/versatile-pb.dtb \
  -kernel ./raspbian_bootpart/kernel-qemu-4.14.*-stretch \
  -append 'root=/dev/sda2 panic=1'\
  -no-reboot

