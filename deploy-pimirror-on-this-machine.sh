#!/bin/bash

MIRRORDIR=/srv/http/mirror

# Update AUR / pacman repos
pacman --noconfirm -Sy

# Install required minimum packages to run our installers
pacman --noconfirm -S git sudo
echo "alarm ALL=(ALL) ALL" >> /etc/sudoers
echo 'Defaults:alarm !authenticate' >> /etc/sudoers # single-quotes are important here because of the bang!

mkdir -p $MIRRORDIR/config
mkdir -p $MIRRORDIR/frontend-build-env
chmod -R 0777 $MIRRORDIR

# Setup backend
echo
echo "Installing backend..."
echo
cd $MIRRORDIR/config
git clone git@bitbucket.org:pimirror/raspberrypi-mirror-configuration.git .
./install.sh

# Setup frontend
echo
echo "Installing frontend..."
echo
cd $MIRRORDIR/mirrorfrontend-build-env
git clone git@bitbucket.org:pimirror/raspberrypi-mirror-framework.git .
./install_arch.sh

IP=`ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p'`
echo
echo "Done! Everything should be online now, as latest version from master branches."
echo "Mirror is @ http://$IP/mirror/"
echo "Config is @ http://$IP/mirror/config.html (Config API @ http://$IP/mirror/config/)"
