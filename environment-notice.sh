#!/bin/bash
echo "----------------------------------------------------------------------------------------"
echo ATTENTION: The default keyboard layout of the virtual pi is en! So it\'s QWERTY layout!
echo "           You can avoid that, if you start the ssh daemon (sudo systemctl start ssh)"
echo "           in the emulated environment and connect with ssh -p 5022 pi@localhost from "
echo "           your host environment."
echo
echo "           To globally change the layout, and other config stuff, run sudo raspi-config"
echo "           in the emulated environment. Oh and by the way, use [CTRL]+[ALT] to release "
echo "           the keyboard focus of the qemu window again."
echo "----------------------------------------------------------------------------------------"
