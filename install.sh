#!/bin/bash

# Setup env
sudo apt-get update
sudo apt-get install -y qemu qemu-system git wget unzip kpartx fdisk libarchive-tools sed uml-utilities bridge-utils net-tools sshpass dconf-cli #In case you wonder why git is here too, I distribute this not only by git...

# Init git
#if [ ! -d ".git" ]; then
#	git clone https://github.com/mcdope/raspberrypi-dev-environment .
#fi

TRACKERIGNORE=`dconf read /org/freedesktop/tracker/miner/files/ignored-directories | cut -d '[' -f 2 | cut -d ']' -f 1`
if [[ ${TRACKERIGNORE} != *"$PWD"* ]]; then
    dconf write /org/freedesktop/tracker/miner/files/ignored-directories "[$TRACKERIGNORE, '$PWD']"
fi

./update.sh

echo
echo "Done!"
echo "You can now boot the emulated enviroment by running boot.sh and logging in with user alarm and password alarm (root password is root)."
echo "To become root, you can either use 'sudo' or 'su', whatever you prefer."
echo
echo "... but your ssh key was installed too, so you shouldn't need these."