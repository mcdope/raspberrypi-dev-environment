#!/bin/bash

if [ $LOGGING -ne 1 ]; then
    # Serious bash kungfu to log everything, see https://serverfault.com/a/103569
    # We only want to do this, if not done by update.sh already
    exec 3>&1 4>&2
    trap 'exec 2>&4 1>&3' 0 1 2 3
    exec 1>$LOGFILE 2>&1
    LOGGING=1
    # echo' to >&3 if you wanna display shit - everything else below will go to the file 'log.out':
fi

KEYBOARD_LAYOUT=`setxkbmap -query | grep layout | cut -d' ' -f6 | cut -d',' -f1`

# Boot the VM
echo -n "[INFO] Calling boot.sh..." >&3
./boot.sh
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

# Removing previous vm host key from known_hosts
echo "[INFO] Removing previous VM host key from known_hosts..."
echo -n "[INFO] Removing previous VM host key from known_hosts..." >&3
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:5022"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi
echo
echo

echo "[INFO] VM booting... waiting 60s for it to finish booting before continuing..."
echo "[INFO] VM booting... waiting 60s for it to finish booting before continuing..." >&3
echo
echo
sleep 60

# Install ssh key
echo "[INFO] VM should be booted, installing ssh key for alarm and root..."
echo -n "[INFO] VM should be booted, installing ssh key for alarm and root..." >&3
echo
# note: we disable hostkeychecking because we just removed the key of the previous image, so obv its an unknown key
echo "alarm" | sshpass ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub alarm@localhost -p 5022
if [ $? -eq 0 ]; then
    echo -n " ... alarm success!" >&3
else
    echo " ... alarm FAILED!" >&3
    exit 1
fi

echo
# note: this only works because we modified the image in update.sh - default config prohibits this
echo "root" | sshpass ssh-copy-id -i ~/.ssh/id_rsa.pub root@localhost -p 5022
if [ $? -eq 0 ]; then
    echo " ... root success!" >&3
else
    echo " ... root FAILED!" >&3
    exit 1
fi
echo
echo

# Init pacman
echo "[INFO] Initing pacman..."
echo -n "[INFO] Initing pacman..." >&3
echo
ssh root@localhost -p 5022 "pacman-key --init"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi
echo

echo
echo
echo "[INFO] Populating pacman keys..."
echo -n "[INFO] Populating pacman keys..." >&3
ssh root@localhost -p 5022 "pacman-key --populate archlinuxarm"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

echo
echo

echo "[INFO] Updating base system..."
echo -n "[INFO] Updating base system..." >&3
ssh root@localhost -p 5022 "pacman --noconfirm -Syu"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi
echo

echo "[INFO] Setting keyboard layout..."
echo -n "[INFO] Setting keyboard layout..." >&3
ssh root@localhost -p 5022 "localectl set-keymap --no-convert $KEYBOARD_LAYOUT"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi
echo

# Push deploy script into VM
echo "[INFO] Pushing deploy script into VM..."
echo -n "[INFO] Pushing deploy script into VM..." >&3
scp -P 5022 deploy-pimirror-on-this-machine.sh root@localhost:/root/
if [ $? -eq 0 ]; then
    echo -n " ... scp success!" >&3
else
    echo " ... scp FAILED!" >&3
    exit 1
fi

ssh root@localhost -p 5022 "chmod +x /root/deploy-pimirror-on-this-machine.sh"
if [ $? -eq 0 ]; then
    echo " ... chmod success!" >&3
else
    echo " ... chmod FAILED!" >&3
    exit 1
fi
echo

# Deploy ssh-key
echo "[INFO] Pushing ssh-key for repository access into VM..."
echo -n "[INFO] Pushing ssh-key for repository access into VM..." >&3
scp -P 5022 ./.vm-sshkey/* alarm@localhost:/home/alarm/.ssh/
if [ $? -eq 0 ]; then
    echo " ... scp success!" >&3
else
    echo " ... scp FAILED!" >&3
    exit 1
fi

ssh root@localhost -p 5022 "chmod 0600 /home/alarm/.ssh/id_rsa /home/alarm/.ssh/id_rsa.pub"
if [ $? -eq 0 ]; then
    echo " ... chmod success!" >&3
else
    echo " ... chmod FAILED!" >&3
    exit 1
fi
echo
echo

echo "[INFO] Enabling autologin on tty1..."
echo "[INFO] Enabling autologin on tty1..." >&3
ssh root@localhost -p 5022 "mkdir /etc/systemd/system/getty@tty1.service.d"
if [ $? -eq 0 ]; then
    #
else
    echo " ... mkdir FAILED!" >&3
    exit 1
fi

ssh root@localhost -p 5022 "echo '[Service]' > /etc/systemd/system/getty@tty1.service.d/override.conf"
if [ $? -eq 0 ]; then
    #
else
    echo " ... echo 1 FAILED!" >&3
    exit 1
fi

ssh root@localhost -p 5022 "echo 'ExecStart=' >> /etc/systemd/system/getty@tty1.service.d/override.conf"
if [ $? -eq 0 ]; then
    #
else
    echo " ... echo 2 FAILED!" >&3
    exit 1
fi

ssh root@localhost -p 5022 "echo 'ExecStart=-/usr/bin/agetty --autologin alarm --noclear %I \$TERM' >> /etc/systemd/system/getty@tty1.service.d/override.conf"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... echo 3 FAILED!" >&3
    exit 1
fi

echo
echo

echo "[INFO] Ensure VM will use bridged networking as primary connection..."
echo -n "[INFO] Ensure VM will use bridged networking as primary connection..." >&3
ssh alarm@localhost -p 5022 "echo '# Enforce using bridged networking by lower metric' > ~/.bash_profile"
if [ $? -eq 0 ]; then
    #
else
    echo " ... echo 1 FAILED!" >&3
    exit 1
fi

ssh alarm@localhost -p 5022 "echo \"sudo ip route add default via \$(ip route | grep default | grep -v \"10.0\" | awk '{print \$3}') metric 100\" >> ~/.bash_profile"
if [ $? -eq 0 ]; then
    #
else
    echo " ... echo 2 FAILED!" >&3
    exit 1
fi

ssh alarm@localhost -p 5022 "echo \"export QTWEBENGINE_REMOTE_DEBUGGING=\$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*\$/\1/p'):9999\" >> ~/.bash_profile"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... echo 3 FAILED!" >&3
    exit 1
fi

echo
echo

echo "[INFO] Running deploy script in VM..."
echo -n "[INFO] Running deploy script in VM..." >&3
time ssh root@localhost -p 5022 "/root/deploy-pimirror-on-this-machine.sh"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

echo
echo

echo "[INFO] Disable password login for root over ssh (got enabled by update.sh)..."
echo -n "[INFO] Disable password login for root over ssh (got enabled by update.sh)..." >&3
ssh root@localhost -p 5022 "sed -i 's/PermitRootLogin prohibit-password/#PermitRootLogin yes/g' /etc/ssh/sshd_config"
if [ $? -eq 0 ]; then
    echo " ... success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

# ... we are a bit paranoid and ensure we have a consistent image
echo "[INFO] Syncing HDD image and shutdown VM..."
echo -n "[INFO] Syncing HDD image and shutdown VM..." >&3
ssh root@localhost -p 5022 "sync"
if [ $? -eq 0 ]; then
    echo -n " ... sync success!" >&3
else
    echo " ... FAILED!" >&3
    exit 1
fi

ssh root@localhost -p 5022 "shutdown now"
if [ $? -eq 0 ]; then
    echo " ... shutdown success!" >&3
else
    echo " ... shutdown FAILED!" >&3
    exit 1
fi

sleep 10
