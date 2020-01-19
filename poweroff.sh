#!/bin/sh

xmessage 'Do you want to shutdown?' \
	-buttons 'Cancel:1,Shut Down:2'

case $? in
    2) systemctl poweroff
	;;
esac
