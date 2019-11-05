#!/bin/bash
LANIFACE=$(ip route get 1.1.1.1 | grep -Po '(?<=dev\s)\w+' | cut -f1 -d ' ')
echo $LANIFACE > /tmp/netbridge_interface

echo "Creating bridge over $LANIFACE..."
brctl addbr br0
ip addr flush dev $LANIFACE
brctl addif br0 $LANIFACE
tunctl -t tap0 -u `whoami`
brctl addif br0 tap0

echo "Bringing interfaces up..."
ifconfig $LANIFACE up
ifconfig tap0 up
ifconfig br0 up

echo "Get IP..."
dhclient -v br0