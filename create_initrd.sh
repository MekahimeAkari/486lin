#!/bin/sh

if [ -z "${DIST_DISK}" ]
then
    echo "\$DIST_DISK undefined"
    exit 1
fi

if [ -z "${DIST_INITRD}" ]
then
    echo "\$DIST_INITRD undefined"
    exit 1
fi

OLD_PWD="${PWD}"

cd "${DIST_INITRD}"

cat << EOF > etc/inittab
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF

cat << EOF > etc/fstab
proc    /proc proc defaults 0 0
sysfs   /sys  sysfs  defaults 0 0
devtmpfs /dev  devtmpfs defaults 0 0
EOF

cat << EOF > etc/init.d/rcS
#!/bin/sh
/bin/mount -a
EOF
chmod +x etc/init.d/rcS

cat << EOF > init
#!/bin/sh

rescue()
{
    echo "Dropping to rescue shell"
    /bin/busybox sh
}

attempt()
{
    echo \$1
    \$2 || { echo "\$1 failed";  rescue; }
    echo "Done"
}

attempt "Mounting devtmpfs" "mount -t devtmpfs none /dev"
attempt "Mounting proc" "mount -t proc none /proc"
attempt "Mounting sysfs" "mount -t sysfs none /sys"

echo "Loading drivers..."
for i in \$(cat /sys/bus/*/devices/*/uevent | grep MODALIAS | cut -d = -f 2 | sort | uniq); do modprobe "\$i" 2>/dev/null; done
echo "Done"
echo ""
echo "Running shell"
/bin/busybox sh
EOF
chmod +x init

find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > "${DIST_DISK}/isolinux/initrd.gz"

cd "${OLD_PWD}"
