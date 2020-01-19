#!/bin/sh

xmessage 'Do you want to reboot?' \
	-buttons 'Cancel:1,Reboot:2'

case $? in
    2)
	systemctl reboot
	;;
esac
