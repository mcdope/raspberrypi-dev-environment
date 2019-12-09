#!/bin/bash

KEYBOARD_LAYOUT=`setxkbmap -query | grep layout | cut -d' ' -f6 | cut -d',' -f1`

# Boot the VM
echo -n "[INFO] Calling boot.sh..."
./boot.sh
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

# Removing previous vm host key from known_hosts
echo -n "[INFO] Removing previous VM host key from known_hosts..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:5022"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi
echo
echo

echo "[INFO] VM booting... waiting 60s for it to finish booting before continuing..."
echo
echo
sleep 60

# Install ssh key
echo -n "[INFO] VM should be booted, installing ssh key for alarm and root..."
# note: we disable hostkeychecking because we just removed the key of the previous image, so obv its an unknown key
echo "alarm" | sshpass ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub alarm@localhost -p 5022
if [ $? -eq 0 ]; then
    echo -n " ... alarm success!"
else
    echo " ... alarm FAILED!"
    exit 1
fi

# note: this only works because we modified the image in update.sh - default config prohibits this
echo "root" | sshpass ssh-copy-id -i ~/.ssh/id_rsa.pub root@localhost -p 5022
if [ $? -eq 0 ]; then
    echo " ... root success!"
else
    echo " ... root FAILED!"
    exit 1
fi
echo
echo

# Init pacman
echo -n "[INFO] Initing pacman..."
echo
ssh root@localhost -p 5022 "pacman-key --init"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi
echo

echo
echo
echo -n "[INFO] Populating pacman keys..."
ssh root@localhost -p 5022 "pacman-key --populate archlinuxarm"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

echo
echo

echo -n "[INFO] Updating base system..."
ssh root@localhost -p 5022 "pacman --noconfirm -Syu"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi
echo

# @todo: (20191209) seems this doesn't work anymore. neither local nor ssh login is possible with this active.
# echo -n "[INFO] Setting keyboard layout..."
# ssh root@localhost -p 5022 "localectl set-keymap --no-convert $KEYBOARD_LAYOUT"
# if [ $? -eq 0 ]; then
    # echo " ... success!"
# else
    # echo " ... FAILED!"
    # exit 1
# fi
# echo

# Push deploy script into VM
echo -n "[INFO] Pushing deploy script into VM..."
scp -P 5022 deploy-pimirror-on-this-machine.sh root@localhost:/root/
if [ $? -eq 0 ]; then
    echo -n " ... scp success!"
else
    echo " ... scp FAILED!"
    exit 1
fi

ssh root@localhost -p 5022 "chmod +x /root/deploy-pimirror-on-this-machine.sh"
if [ $? -eq 0 ]; then
    echo " ... chmod success!"
else
    echo " ... chmod FAILED!"
    exit 1
fi
echo

# Deploy ssh-key
echo -n "[INFO] Pushing ssh-key for repository access into VM..."
scp -P 5022 ./.vm-sshkey/* alarm@localhost:/home/alarm/.ssh/
if [ $? -eq 0 ]; then
    echo " ... scp success!"
else
    echo " ... scp FAILED!"
    exit 1
fi

ssh root@localhost -p 5022 "chmod 0600 /home/alarm/.ssh/id_rsa /home/alarm/.ssh/id_rsa.pub"
if [ $? -eq 0 ]; then
    echo " ... chmod success!"
else
    echo " ... chmod FAILED!"
    exit 1
fi
echo
echo

echo -n "[INFO] Enabling autologin on tty1..."
ssh root@localhost -p 5022 "mkdir /etc/systemd/system/getty@tty1.service.d"
if [ $? -eq 0 ]; then
    echo -n " ... mkdir success!"
else
    echo " ... mkdir FAILED!"
    exit 1
fi

ssh root@localhost -p 5022 "echo '[Service]' > /etc/systemd/system/getty@tty1.service.d/override.conf"
if [ $? -eq 0 ]; then
    echo -n " ... echo 1 success!"
else
    echo " ... echo 1 FAILED!"
    exit 1
fi

ssh root@localhost -p 5022 "echo 'ExecStart=' >> /etc/systemd/system/getty@tty1.service.d/override.conf"
if [ $? -eq 0 ]; then
    echo -n " ... echo 2 success!"
else
    echo " ... echo 2 FAILED!"
    exit 1
fi

ssh root@localhost -p 5022 "echo 'ExecStart=-/usr/bin/agetty --autologin alarm --noclear %I \$TERM' >> /etc/systemd/system/getty@tty1.service.d/override.conf"
if [ $? -eq 0 ]; then
    echo " ... echo 3 success!"
else
    echo " ... echo 3 FAILED!"
    exit 1
fi

echo
echo

echo -n "[INFO] Ensure VM will use bridged networking as primary connection..."
ssh alarm@localhost -p 5022 "echo '# Enforce using bridged networking by lower metric' > ~/.bash_profile"
if [ $? -eq 0 ]; then
    echo -n " ... echo 1 success!"
else
    echo " ... echo 1 FAILED!"
    exit 1
fi

ssh alarm@localhost -p 5022 "echo \"sudo ip route add default via \$(ip route | grep default | grep -v \"10.0\" | awk '{print \$3}') metric 100\" >> ~/.bash_profile"
if [ $? -eq 0 ]; then
    echo " ... echo 2 success!"
else
    echo " ... echo 2 FAILED!"
    exit 1
fi

ssh alarm@localhost -p 5022 "echo \"export QTWEBENGINE_REMOTE_DEBUGGING=\$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*\$/\1/p'):9999\" >> ~/.bash_profile"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... echo 3 FAILED!"
    exit 1
fi

echo
echo

echo -n "[INFO] Running deploy script in VM..."
time ssh root@localhost -p 5022 "/root/deploy-pimirror-on-this-machine.sh"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

echo
echo

echo -n "[INFO] Disable password login for root over ssh (got enabled by update.sh)..."
ssh root@localhost -p 5022 "sed -i 's/PermitRootLogin prohibit-password/#PermitRootLogin yes/g' /etc/ssh/sshd_config"
if [ $? -eq 0 ]; then
    echo " ... success!"
else
    echo " ... FAILED!"
    exit 1
fi

# ... we are a bit paranoid and ensure we have a consistent image
echo -n "[INFO] Syncing HDD image and shutdown VM..."
ssh root@localhost -p 5022 "sync"
if [ $? -eq 0 ]; then
    echo -n " ... sync success!"
else
    echo " ... FAILED!"
    exit 1
fi

ssh root@localhost -p 5022 "shutdown now"
if [ $? -eq 0 ]; then
    echo " ... shutdown success!"
else
    echo " ... shutdown FAILED!"
    exit 1
fi

sleep 10
