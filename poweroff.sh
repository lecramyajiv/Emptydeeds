#!/bin/sh

xmessage -center 'Do you want to shutdown your Computer?' \
	 -buttons 'Cancel:1,Shut Down:2'

answer=$?

case $answer in
1) xmessage -center "Aborted" 
	;;
2) systemctl poweroff 
	;;
esac

