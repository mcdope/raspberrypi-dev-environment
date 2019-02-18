#!/bin/bash

# Update repo and device/kernel submodule
git fetch
git pull --recurse-submodules

# Get OS
# wget https://downloads.raspberrypi.org/raspbian_lite_latest # <-- Original OS
wget -O raspbian_lite_latest https://www.dropbox.com/s/u1dxfboxr4drg5k/raspbian-stretch-lite.grown.updated.pimirror.zip?dl=0 # <-- pimirror variant - pregrown, customized, updated and preinstalled
unzip -o raspbian_lite_latest
mv *-raspbian-stretch-lite.img raspbian-stretch-lite.img #to make it have a known name so we dont need to grep around
rm raspbian_lite_latest
