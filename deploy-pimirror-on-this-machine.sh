#!/bin/bash

MIRRORDIR=/srv/http/mirror

# Update AUR / pacman repos
pacman --noconfirm -Sy

# Install required minimum packages to run our installers and configure sudo for password-less POWAAAAAAAAH
pacman --noconfirm -S git sudo
echo "alarm ALL=(ALL) ALL" >> /etc/sudoers
echo 'Defaults:alarm !authenticate' >> /etc/sudoers # single-quotes are important here because of the bang!

usermod -a -G http alarm
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
sudo -u alarm GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone git@bitbucket.org:pimirror/raspberrypi-mirror-configuration.git . && sudo -u alarm ./install.sh

# Setup frontend
echo
echo "Cloning frontend..."
echo
cd $MIRRORDIR/frontend-build-env
sudo -u alarm GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone git@bitbucket.org:pimirror/raspberrypi-mirror-framework.git .

echo
echo "Preloading frontend node_modules..."
wget ftp://pimirror:p1m1rr0r@mcdope.org/npm_preload.tar.gz
tar xzf npm_preload.tar.gz
rm npm_preload.tar.gz

echo
echo "Installing frontend..."
sudo -u alarm ./install_arch.sh Virtual-1


chown -R alarm:http $MIRRORDIR

IP=`ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p'`
echo
echo "Done! Everything should be online now, as latest version from master branches."
echo "Mirror is @ http://$IP/mirror/"
echo "Config is @ http://$IP/mirror/config.html (Config API @ http://$IP/mirror/config/)"
