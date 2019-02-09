#!/bin/bash

# Setup env
sudo apt-get update
sudo apt-get install -y qemu git wget unzip #In case you wonder why git is here too, I distribute this not only by git...

# Init git
if [ ! -d ".git" ]; then
	git clone https://github.com/mcdope/raspberrypi-dev-environment .
fi

./update.sh

echo
echo Done!
echo You can now boot the emulated enviroment by running boot.sh and logging in with user pi and password raspberry.
echo
./environment-notice.sh
