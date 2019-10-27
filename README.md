# What is this?

An installer for an emulated Raspberry Pi Environment. Though, we use another device definition so we can use the current Rasbian image.

## Licence

GPLv3 for my scripts, for thirdparty stuff used you need to find out yourself.

## Install

To install, run install.sh. This will prepare your Debian based (tested on Ubuntu only) host enviroment for the VM and invoke update.sh for you.

## Update

To update, run update.sh. This will backup your current VM image if it exists and create a new one. Afterwards it will partition it, create filesystems, 
download the lastest arch-arm for pi3 and install it on the image. Then another script, init_arch.sh, will init the system (install ssh keys, prepare system etc.)

## Boot

To boot, guess what... You run boot.sh

### Credits

- Wim Vanderbauwhede - [Raspbian "stretch" for Raspberry Pi 3 on QEMU](https://github.com/wimvanderbauwhede/limited-systems/wiki/Raspbian-%22stretch%22-for-Raspberry-Pi-3-on-QEMU), [Debian "buster" for Raspberry Pi 3 on QEMU](https://github.com/wimvanderbauwhede/limited-systems/wiki/Debian-%22buster%22-for-Raspberry-Pi-3-on-QEMU)

