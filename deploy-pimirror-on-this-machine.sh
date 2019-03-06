#!/bin/bash

mkdir -p /var/www/html/mirror/config
mkdir -p /var/www/html/mirror/frontend-build-env

# Setup backend
mkdir config
cd /var/www/html/mirror/config
git clone https://bitbucket.org/pimirror/raspberrypi-mirror-configuration.git .
./install.sh

# Setup frontend
cd /var/www/html/mirrorfrontend-build-env
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
