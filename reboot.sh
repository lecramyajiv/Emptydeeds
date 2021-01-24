#!/bin/sh

xmessage -center 'Do you want to Restart your Computer?' \
	 -buttons 'Cancel:1, Reboot:2'

answer=$?

case $answer in
1) xmessage -center "Aborted" 
	;;
2) systemctl reboot 
	;;
esac


