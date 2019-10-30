#!/bin/bash

MIRRORDIR=/srv/http/mirror

# Update AUR / pacman repos
pacman --noconfirm -Sy

# Install required minimum packages to run our installers and configure sudo for password-less POWAAAAAAAAH
pacman --noconfirm -S git sudo
echo "alarm ALL=(ALL) ALL" >> /etc/sudoers
echo 'Defaults:alarm !authenticate' >> /etc/sudoers # single-quotes are important here because of the bang!

mkdir -p $MIRRORDIR/raspberrypi-mirror-configuration
ln -s $MIRRORDIR/raspberrypi-mirror-configuration/php-src $MIRRORDIR/config
mkdir -p $MIRRORDIR/frontend-build-env

# Create inotify dir
mkdir -p $MIRRORDIR/inotify_sockets

# Setup backend
echo
echo "Installing backend..."
echo
chmod -R 0777 $MIRRORDIR
cd $MIRRORDIR/raspberrypi-mirror-configuration
sudo -u alarm git clone git@bitbucket.org:pimirror/raspberrypi-mirror-configuration.git .
sudo -u alarm ./install.sh

# Setup frontend
echo
echo "Installing frontend..."
echo
cd $MIRRORDIR/mirrorfrontend-build-env
sudo -u alarm git clone git@bitbucket.org:pimirror/raspberrypi-mirror-framework.git .
sudo -u alarm ./install_arch.sh

chown -R http:alarm $MIRRORDIR

IP=`ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p'`
echo
echo "Done! Everything should be online now, as latest version from master branches."
echo "Mirror is @ http://$IP/mirror/"
echo "Config is @ http://$IP/mirror/config.html (Config API @ http://$IP/mirror/config/)"
