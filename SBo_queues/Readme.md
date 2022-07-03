
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

add libconfig | DOC=yes EXAMPLES=yes

add the following line to /lib/udev/rules.d/65-permissions.rules 

kernel=="raw1394",              GROUP="disk"

to disable elevated privilages in jack modify the quefile by jack | SETCAP=no this is optional
