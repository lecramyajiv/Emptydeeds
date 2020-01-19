#!/bin/sh

xmessage 'Do you want to Logout?' \
	-buttons 'Cancel:1,Logout:2'

case $? in
    2)  pkill -KILL -u ben
	;;
esac