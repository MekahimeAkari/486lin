#!/bin/sh
set -ex

if [ -z "${DIST_ROOT}" ]
then
    echo "\$DIST_ROOT undefined"
    exit 1
fi

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

cd "${DIST_ROOT}"
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
echo "Loading drivers..."
for i in \$(cat /sys/bus/*/devices/*/uevent | grep MODALIAS | cut -d = -f 2 | sort | uniq); do modprobe "\$i" 2>/dev/null; done
EOF
chmod +x etc/init.d/rcS

cd "${OLD_PWD}"
cd "${DIST_INITRD}"

rm -rf lib/modules
cp -a "${DIST_ROOT}/lib/modules" lib/
rm -rf lib/modules/*/*.bin
rm -rf lib/modules/*/kernel/net
rm -rf lib/modules/*/kernel/sound
rm -rf lib/modules/*/kernel/crypto
rm -rf lib/modules/*/kernel/fs/nfs*
rm -rf lib/modules/*/kernel/fs/ntfs*
rm -rf lib/modules/*/kernel/fs/exfat
rm -rf lib/modules/*/kernel/fs/smb*
rm -rf lib/modules/*/kernel/fs/lockd
rm -rf lib/modules/*/kernel/fs/fuse
rm -rf lib/modules/*/kernel/drivers/gpu
rm -rf lib/modules/*/kernel/drivers/net
rm -rf lib/modules/*/kernel/drivers/usb/serial
rm -rf lib/modules/*/kernel/drivers/usb/storage
rm -rf lib/modules/*/kernel/drivers/usb/misc
rm -rf lib/modules/*/kernel/drivers/usb/cdns3
rm -rf lib/modules/*/kernel/drivers/platform
rm -rf lib/modules/*/kernel/drivers/hwmon
rm -rf lib/modules/*/kernel/drivers/media
rm -rf lib/modules/*/kernel/drivers/scsi/*iscsi*
rm -rf lib/modules/*/kernel/drivers/input/mouse*
rm -rf lib/modules/*/kernel/drivers/input/rmi4
rm -rf lib/modules/*/kernel/drivers/input/joydev
rm -rf lib/modules/*/kernel/drivers/input/misc
rm -rf lib/modules/*/kernel/drivers/input/gameport
rm -rf lib/modules/*/kernel/drivers/input/ff-memless*
rm -rf lib/modules/*/kernel/drivers/i2c
rm -rf lib/modules/*/kernel/drivers/leds
rm -rf lib/modules/*/kernel/drivers/crypto
rm -rf lib/modules/*/kernel/drivers/pinctrl
rm -rf lib/modules/*/kernel/drivers/mfd
rm -rf lib/modules/*/kernel/drivers/firewire
rm -rf lib/modules/*/kernel/drivers/char
rm -rf lib/modules/*/kernel/drivers/acpi/dptf
rm -rf lib/modules/*/kernel/drivers/acpi/button*
rm -rf lib/modules/*/kernel/drivers/acpi/battery*
rm -rf lib/modules/*/kernel/drivers/acpi/acpi_pad*
rm -rf lib/modules/*/kernel/drivers/acpi/sbs*
rm -rf lib/modules/*/kernel/drivers/acpi/video*
rm -rf lib/modules/*/kernel/drivers/hid
rm -rf lib/modules/*/kernel/block
cat << EOF > init
#!/bin/sh

ZRAM_SIZE="64M"
rescue()
{
    echo "Dropping to rescue shell"
    /bin/busybox sh
    exit
}

echo "Mounting devtmpfs..."
mount -t devtmpfs none /dev || { echo "fail"; rescue; }
echo "ok"
echo -"Mounting proc..."
mount -t proc none /proc || { echo "fail"; rescue; }
echo "ok"
echo "Mounting sysfs..."
mount -t sysfs none /sys || { echo "fail"; rescue; }
echo "ok"
echo "Loading drivers..."
for i in \$(cat /sys/bus/*/devices/*/uevent | grep MODALIAS | cut -d = -f 2 | sort | uniq); do modprobe "\$i" 2>/dev/null; done
echo "done"
echo "Making new root dirs... "
mkdir -p /mnt/zram
mkdir -p /mnt/cdrom
mkdir -p /mnt/squash
mkdir -p /mnt/newroot
echo "ok"
echo "Setting ZRAM size to \${ZRAM_SIZE}..."
echo "\${ZRAM_SIZE}" > /sys/block/zram0/disksize || { echo "fail"; rescue; }
echo "ok"
echo "Creating fs on /dev/zram0..."
mkfs.ext2 -b 4096 /dev/zram0 || { echo "fail"; rescue; }
echo "Mounting ZRAM..."
mount -t ext2 /dev/zram0 /mnt/zram || { echo "fail"; rescue; }
echo "ok"
mkdir -p /mnt/zram/upper
mkdir -p /mnt/zram/work
echo "Mounting cdrom (/dev/sr0)..."
mount -o ro /dev/sr0 /mnt/cdrom || { echo "fail"; rescue; }
echo "ok"
echo "Mounting squashfs..."
mount -o ro,loop -t squashfs /mnt/cdrom/root.sfs /mnt/squash || { echo "fail"; rescue; }
echo "ok"
echo "Mounting overlay..."
mount -t overlay overlay -o lowerdir=/mnt/squash,upperdir=/mnt/zram/upper,workdir=/mnt/zram/work /mnt/newroot || { echo "fail"; rescue; }
echo "ok"
echo ""
echo "Switching root..."
exec switch_root /mnt/newroot /sbin/init || { echo "Switching root failed"; rescue; }
EOF
chmod +x init

find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > "${DIST_DISK}/isolinux/initrd.gz"

cd "${OLD_PWD}"
