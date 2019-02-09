#!/bin/bash

# Update repo and device/kernel submodule
git fetch
git pull --recurse-submodules

# Get OS
wget https://downloads.raspberrypi.org/raspbian_lite_latest
unzip -o raspbian_lite_latest
mv *-raspbian-stretch-lite.img raspbian-stretch-lite.img #to make it have a known name so we dont need to grep around
rm raspbian_lite_latest