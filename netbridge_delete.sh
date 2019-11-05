#!/bin/bash
LANIFACE=`cat /tmp/netbridge_interface`

echo "Deleting interfaces from bridge..."
brctl delif br0 tap0
tunctl -d tap0
brctl delif br0 $LANIFACE

echo "Bringing interfaces down..."
ifconfig br0 down
echo "Deleting bridge..."
brctl delbr br0

echo "Bring real interface back up..."
ifconfig $LANIFACE up

echo "Get IP..."
dhclient -v $LANIFACE