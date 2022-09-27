
# Sbopkg queue files

Install order

1. 00-microcode.sqf
2. 01-doc-builder.sqf
3. 02-compiler.sqf
4. 04-Essential-perl.sqf
5. 05-Essential-python.sqf
6. 06-vbox.sqf
7. 07-media-deps.sqf
8. 08-appications.sqf


before installing 07-media-deps.sqf do the following

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

avahi:

before installing avahi add

groupadd -g 214 avahi

useradd -u 214 -g 214 -c "Avahi User" -d /dev/null -s /bin/false avahi

after installing start the Avahi daemon:

	# /etc/rc.d/rc.avahidaemon start

Optionally start the unicast DNS configuration daemon:

	# /etc/rc.d/rc.avahidnsconfd start


You will need to start avahi at boot by adding the following 
to your /etc/rc.d/rc.local and make them executable:

        # Start avahidaemon
	if [ -x /etc/rc.d/rc.avahidaemon ]; then
	  /etc/rc.d/rc.avahidaemon start
	fi
        # Start avahidnsconfd
	if [ -x /etc/rc.d/rc.avahidnsconfd ]; then
	  /etc/rc.d/rc.avahidnsconfd start
	fi

You will also want to put the following into /etc/rc.d/rc.local_shutdown
(if that file does not exist, create it and make it executable):

        # Stop avahidnsconfd
	if [ -x /etc/rc.d/rc.avahidnsconfd ]; then
	  /etc/rc.d/rc.avahidnsconfd stop
	fi
        # Stop avahidaemon
	if [ -x /etc/rc.d/rc.avahidaemon ]; then
	  /etc/rc.d/rc.avahidaemon stop
	fi
