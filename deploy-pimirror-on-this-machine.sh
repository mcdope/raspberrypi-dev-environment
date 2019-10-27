#!/bin/bash

MIRRORDIR=/srv/http/mirror

# Update AUR / pacman repos
pacman --noconfirm -Sy

# Install required minimum packages to run our installers
pacman --noconfirm -S git sudo
mkdir -p $MIRRORDIR/config
mkdir -p $MIRRORDIR/frontend-build-env

# Setup backend
echo
echo "Installing backend..."
echo
mkdir config
cd $MIRRORDIR/config
git clone https://bitbucket.org/pimirror/raspberrypi-mirror-configuration.git .
./install.sh

# Setup frontend
echo
echo "Installing frontend..."
echo
cd $MIRRORDIR/mirrorfrontend-build-env
git clone https://bitbucket.org/pimirror/raspberrypi-mirror-framework.git .
npm install && npm run build && yes | cp -rf ./dist/* ../

# Change Apache config to allow .htaccess usage in /var/www
# WARNING: YOU DONT WANT TO RUN THIS ON A PRODUCTION SYSTEM! IT COULD OPEN HOLES!
# Don't say I didn't warned you...
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/sites-available/000-default.conf
systemctl reload apache2

IP=`ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p'`
echo
echo "Done! Everything should be online now, as latest version from master branches."
echo "Mirror is @ http://$IP/mirror/"
echo "Config is @ http://$IP/mirror/config.html (Config API @ http://$IP/mirror/config/)"
