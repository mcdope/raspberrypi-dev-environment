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

# Upgrade system
# note: arch is a rolling distri, so maybe this isnt exactly smart, 
# i.e largerswitches causing breaking. So keep in mind...
#echo "Upgrading system..."
#ssh root@localhost -p 5022 "pacman --noconfirm -Syu"

# Updating arch_bootpart for qemu
#echo "Copying updated /boot to arch_bootpart..."
#if [ -d "arch_bootpart" ]; then
#    rm -rf arch_bootpart
#    echo "Info: removed previous arch_bootpart"
#    mkdir arch_bootpart
#fi
#scp -r -P 5022 arch_bootpart root@localhost:/boot

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

# ... we are a bit paranoid and ensure we have a consistent image
echo "Syncing HDD image and shutdown VM..."
ssh root@localhost -p 5022 "sync"
ssh root@localhost -p 5022 "shutdown now" 2>&1 /dev/null
sleep 10
