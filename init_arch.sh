#!/bin/bash

KEYBOARD_LAYOUT=`setxkbmap -query | grep layout | cut -d' ' -f6 | cut -d',' -f1`

# Boot the VM
./boot.sh > /dev/null

# Removing previous vm host key from known_hosts
echo "Removing previous VM host key from known_hosts..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:5022" > /dev/null
echo
echo

echo "VM booting... waiting 60s for it to finish booting before continuing..."
echo
echo
sleep 60

# Install ssh key
echo "VM should be booted, installing ssh key for alarm and root..."
echo
# note: we disable hostkeychecking because we just removed the key of the previous image, so obv its an unknown key
echo "alarm" | sshpass ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub alarm@localhost -p 5022 > /dev/null
echo
# note: this only works because we modified the image in update.sh - default config prohibits this
echo "root" | sshpass ssh-copy-id -i ~/.ssh/id_rsa.pub root@localhost -p 5022 > /dev/null
echo
echo

# Init pacman
echo "Initing pacman..."
echo
ssh root@localhost -p 5022 "pacman-key --init" > /dev/null
echo
echo
echo
echo "Populating pacman keys..."
ssh root@localhost -p 5022 "pacman-key --populate archlinuxarm" > /dev/null
echo
echo

echo "Setting keyboard layout..."
ssh root@localhost -p 5022 "localectl set-keymap --no-convert $KEYBOARD_LAYOUT" > /dev/null
echo

# Push deploy script into VM
echo "Pushing deploy script into VM..."
scp -P 5022 deploy-pimirror-on-this-machine.sh root@localhost:/root/
ssh root@localhost -p 5022 "chmod +x /root/deploy-pimirror-on-this-machine.sh"
echo

# Deploy ssh-key
echo "Pushing ssh-key for repository access into VM..."
scp -P 5022 ./.vm-sshkey/* alarm@localhost:/home/alarm/.ssh/
echo
echo

echo "Enabling autologin on tty1..."
ssh root@localhost -p 5022 "mkdir /etc/systemd/system/getty@tty1.service.d"
ssh root@localhost -p 5022 "echo '[Service]' > /etc/systemd/system/getty@tty1.service.d/override.conf"
ssh root@localhost -p 5022 "echo 'ExecStart=' >> /etc/systemd/system/getty@tty1.service.d/override.conf"
ssh root@localhost -p 5022 "echo 'ExecStart=-/usr/bin/agetty --autologin alarm --noclear %I \$TERM' >> /etc/systemd/system/getty@tty1.service.d/override.conf"
echo
echo

echo "Ensure VM will use bridged networking as primary connection..."
ssh alarm@localhost -p 5022 "echo '# Enforce using bridged networking by lower metric' > ~/.bash_profile"
ssh alarm@localhost -p 5022 "echo \"ip route add default via $(ip route | grep default | grep -v \"10.0\" | awk '{print $3}') metric 100\" >> ~/.bash_profile"
ssh alarm@localhost -p 5022 "echo \"export QTWEBENGINE_REMOTE_DEBUGGING=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p'):9999\" >> ~/.bash_profile"
echo
echo

echo "Running deploy script in VM..."
time ssh root@localhost -p 5022 "/root/deploy-pimirror-on-this-machine.sh"
echo
echo

echo "Disable password login for root over ssh (got enabled by update.sh)..."
sudo sed -i 's/PermitRootLogin prohibit-password/#PermitRootLogin yes/g' root/etc/ssh/sshd_config

# ... we are a bit paranoid and ensure we have a consistent image
echo "Syncing HDD image and shutdown VM..."
ssh root@localhost -p 5022 "sync"
ssh root@localhost -p 5022 "shutdown now" 2>&1 /dev/null
sleep 10
