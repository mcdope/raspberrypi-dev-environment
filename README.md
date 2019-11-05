# What is this?

An installer for an emulated Raspberry Pi3 Environment. This isn't intended as an accurate emulation, but more as a development testbed.

You can expect approx. 50% Pi3 speed with this VM, qemu aarch64 is just too slow to get more speed out of it. The operating system used 
is Arch Linux ARM in the Pi3 variant and will use a 8GB imagefile as storage. For more comfort auto-login on tty1 as user alarm will be
enabled. Also the script will install your ssh key for users alarm and root so you can easily connect by ssh. Networking will be bridged
to whatever network you use with Internet connection.

## What doesn't work?

Everything Raspberry Pi specific. This VM uses the "virt" board, so it's just some random ARM 64bit box with similiar hardware specs. 
But it's not an accurate replica of a real Pi.

## Requirements

- somehow current PC
- Ubuntu 19.04 or later (other Debian based distributions may work too, but totally untested)
- sudo access
- Internet connection
- about 10GB free drive space (8GB for the image file, about 520MB for Arch Linux download, some security reserve)

## Licence

GPLv3 for my scripts, for thirdparty stuff used you need to find out yourself.

## Disclaimer

The scripts in this repo use sudo a lot, and also do disk partioning; formatting and (u)mounting. 

Please read the scripts before you use them and understand what they do. Don't just trust me. Not that I have malicious intentions, 
but good pratice etc etc. Also, bugs happen and I can't test on every system on the planet...

Don't blame me when something breaks because of this.

# Important note about errors / error handling

All scripts have no error handling, they expect to "just work". Obviously this will break when I assume something to be default when it is not or 
similiar. So carefully take a look at the scripts output for informations if you have any problems.

Feel free to open an issue, I will see how I can help.

# Important note about networking

The VM uses two networking connections. One for host-only networking with portforwarding to have a known address to connect to for setup. The other one
for external networking, which will be forced as default connection. This uses a bridge named br0 which will be created by netbridge_create.sh when you
run install.sh. It will autodetect your network connection to use for the bridge, but I only tested it with wired connections. Your mileage with WiFi, 
or even multiple, connections will vary.

## Removing the network bridge create by install.sh/netbridge_create.sh

To cleanly remove the bridge connection you can use the script netbridge_delete.sh (use sudo / a root shell). But you don't need to do that
since it's not persistent - means: will be removed on reboot.

# sudo (make me a sandwich)

Quite some commands will use sudo, I recommend to setup sudo for password-less auth by using an USB-Key or similiar. It's not required, but 
depending on how fast the scripts run on your computer and how long the auth gets cached it could become annoying. Just saying ¯\_(ツ)_/¯

# Install

To install, run install.sh. This will prepare your Debian based (tested on Ubuntu only) host enviroment for the VM, create the network bridge and 
invoke update.sh for you.

# Update

To update, run update.sh. This will backup your current VM image if it exists and create a new one. Afterwards it will partition it, create filesystems, 
download the lastest arch-arm for pi3 and install it on the image. Then another script, init_arch.sh, will init the system (install ssh keys, prepare system etc.)

This process take quite some time. On my oc'ed i5 3rd gen with 24GB RAM it takes like 35min to fully build the VM image. It's slowed down by my
crappy 60Mbit connection, but you should expect times around that nonetheless.

# Boot

To boot, guess what... You run boot.sh

# Credits

- Wim Vanderbauwhede - [Raspbian "stretch" for Raspberry Pi 3 on QEMU](https://github.com/wimvanderbauwhede/limited-systems/wiki/Raspbian-%22stretch%22-for-Raspberry-Pi-3-on-QEMU), [Debian "buster" for Raspberry Pi 3 on QEMU](https://github.com/wimvanderbauwhede/limited-systems/wiki/Debian-%22buster%22-for-Raspberry-Pi-3-on-QEMU)
- countless other resources, and Google
