#!/bin/bash

# Setup env
sudo apt-get update
sudo apt-get install -y qemu git #In case you wonder why git is here too, I distribute this not only by git...

# Get OS
wget https://downloads.raspberrypi.org/raspbian_lite_latest
unzip -o raspbian_lite_latest
mv *-raspbian-stretch-lite.img raspbian-stretch-lite.img #to make it have a known name so we dont need to grep around
rm raspbian_lite_latest

# Get Kernel and DTB
git clone git@github.com:dhruvvyas90/qemu-rpi-kernel.git raspbian_bootpart

echo
echo Done!
echo You can now boot the emulated enviroment by running boot.sh and logging in with user pi and password raspberry.
echo
./environment-notice.sh
