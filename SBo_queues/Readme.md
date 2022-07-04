
# Sbopkg queue files

Install order

1. intel-java.sqf
2. Essential-perl.sqf
3. doc-builder.sqf
4. ffmpeg-deps.sqf
5. python-ectx-deps.sqf
6. qemu-deps.sqf

before installing doc-builder.sqf install jai and jai-imageio from SBO

before installing FFmpeg-deps.sqf do the following

optional: add libconfig | DOC=yes EXAMPLES=yes

add the following line to /lib/udev/rules.d/65-permissions.rules 

kernel=="raw1394",              GROUP="disk"

to disable elevated privilages in jack modify the quefile by jack | SETCAP=no this is optional

Optional: In Tesseract to enable different lang packs edit the LANGNAM variable in slackbuild before loading the queue

LANGNAM=${LANGNAM:-"eng hin san tam mal kan tel ben"}

optional: pass the option rubberband | JAVA=YES  this requires zulu-openjdk8

OpenBLAS: If running in virtual machine like qemu pass an argument TARGET=cpuname, list available from Targetlist.txt in source code

Rabbitmq-server: Do this before installing

groupadd -g 319 rabbitmq
useradd  -u 319 -g 319  -c "Rabbit MQ" -d /var/lib/rabbitmq -s /bin/sh rabbitmq
