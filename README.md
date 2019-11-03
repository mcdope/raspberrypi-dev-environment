# What is this?

An installer for an emulated Raspberry Pi3 Environment. This isn't intended as an accurate emulation, but more as a development testbed.

## Licence

GPLv3 for my scripts, for thirdparty stuff used you need to find out yourself.

## Important note about networking

The VM uses two networking connection. One for host-only networking with portforwarding to have a known address to connect to for setup. The other one
for external networking, which will be forced as default connection. This uses a bridge named br0 you have to create before. To do so you can use the 
script "netbridge_create.sh" which will create br0 with your primary wired(!, WiFi untested) interface. To delete the bridge again when you're done you
can use "netbridge_delete.sh".

## Install

To install, run install.sh. This will prepare your Debian based (tested on Ubuntu only) host enviroment for the VM and invoke update.sh for you.

## Update

To update, run update.sh. This will backup your current VM image if it exists and create a new one. Afterwards it will partition it, create filesystems, 
download the lastest arch-arm for pi3 and install it on the image. Then another script, init_arch.sh, will init the system (install ssh keys, prepare system etc.)

## Boot

To boot, guess what... You run boot.sh

### Credits

- Wim Vanderbauwhede - [Raspbian "stretch" for Raspberry Pi 3 on QEMU](https://github.com/wimvanderbauwhede/limited-systems/wiki/Raspbian-%22stretch%22-for-Raspberry-Pi-3-on-QEMU), [Debian "buster" for Raspberry Pi 3 on QEMU](https://github.com/wimvanderbauwhede/limited-systems/wiki/Debian-%22buster%22-for-Raspberry-Pi-3-on-QEMU)
- countless other resources, and Google
