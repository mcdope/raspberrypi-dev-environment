#!/bin/bash

# Boot the VM
./boot.sh > /dev/null

# Removing host key from known_hosts
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:5022"

echo "VM booting... waiting 60s for it to finish booting before continuing..."
sleep 60

# Install ssh key
echo "VM should be booted, installing ssh key for alarm and root..."
# note: we disable hostkeychecking because we just removed the key of the previous image, so obv its an unknown key
echo "alarm" | sshpass ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub alarm@localhost -p 5022

# note: this only works because we modified the image in update.sh - default config prohibits this
echo "root" | sshpass ssh-copy-id -i ~/.ssh/id_rsa.pub root@localhost -p 5022 

# Init pacman
echo "Initing pacman..."
ssh root@localhost -p 5022 "pacman-key --init"
ssh root@localhost -p 5022 "pacman-key --populate archlinuxarm"

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

# ... we are a bit paranoid and ensure we have a consistent image
ssh root@localhost -p 5022 "sync"
ssh root@localhost -p 5022 "shutdown now"
sleep 10

echo
echo "... VM ready, done!"
echo
echo "To start the VM run \"boot.sh\"."
echo "After booting you can connect by running \"ssh -p 5022 alarm@localhost\", or if you want to be root \"ssh -p 5022 root@localhost\""
