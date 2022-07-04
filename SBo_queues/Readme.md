
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

optional: in the sqf file add libconfig | DOC=yes EXAMPLES=yes

add the following line to /lib/udev/rules.d/65-permissions.rules 

kernel=="raw1394",              GROUP="disk"

to disable elevated privilages in jack modify the quefile by jack | SETCAP=no this is optional

Optional: In Tesseract to enable different lang packs edit the LANGNAM variable in slackbuild before loading the queue

LANGNAM=${LANGNAM:-"eng hin san tam mal kan tel ben"}

optional: pass the option rubberband | JAVA=YES in the sqf file, this requires zulu-openjdk8

OpenBLAS: If running in virtual machine like qemu pass an argument TARGET=cpuname, list available from Targetlist.txt in source code

Rabbitmq-server: Do this before installing

groupadd -g 319 rabbitmq
useradd  -u 319 -g 319  -c "Rabbit MQ" -d /var/lib/rabbitmq -s /bin/sh rabbitmq

rabbitmq-c: In the sqf file pass these options

rabbitmq-c | BUILD_EXAMPLES=ON BUILD_TESTS=ON BUILD_TOOLS=ON ENABLE_SSL_SUPPOT=ON BUILD_TOOLS_DOCS=ON RUN_SYSYEM_TESTS=ON

libde265: in the sqf file pass the option, libde265 | SHERLOCK265=yes
