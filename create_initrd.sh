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
KERNEL_VER="$(ls lib/modules)"
rm -rf lib/modules/${KERNEL_VER}/*.bin
rm -rf lib/modules/${KERNEL_VER}/modules.symbols
rm -rf lib/modules/${KERNEL_VER}/kernel/net
rm -rf lib/modules/${KERNEL_VER}/kernel/sound
rm -rf lib/modules/${KERNEL_VER}/kernel/crypto
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/nfs*
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/ntfs*
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/exfat
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/smb*
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/lockd
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/fuse
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/autofs
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/binfmt_misc*
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/hfsplus
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/jbd2
rm -rf lib/modules/${KERNEL_VER}/kernel/fs/ext4
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/gpu
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/net
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/usb/serial
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/usb/storage
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/usb/misc
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/usb/cdns3
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/platform
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/hwmon
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/media
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/*iscsi*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/*raid*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/pcmcia
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/libsas
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/snic
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/hpsa*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/sym53c8xx_2
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/esas2r
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/BusLogic*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/advansys*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/mvsas
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/arcmsr
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/be2iscsi
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/smartpqi
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/aacraid
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/ipr.ko
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/aic94xx
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/mpi3mr
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/pm8001
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/megaraid
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/qla4xxx
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/mpt3sas
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/scsi/aic7xxx
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/mouse*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/rmi4
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/joydev*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/evdev*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/input-leds*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/misc
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/gameport
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/input/ff-memless*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/block/pktcdvd*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/video
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/i2c
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/leds
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/crypto
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/pinctrl
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/mfd
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/firewire
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/char
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/acpi/dptf
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/acpi/button*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/acpi/battery*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/acpi/acpi_pad*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/acpi/sbs*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/acpi/video*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/hid
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/pcmcia
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/block/nbd*
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/parport
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/ssb
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/spmi
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/pps
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/connector
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/gpio
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/misc
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/uio
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/power
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/ptp
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/phy
rm -rf lib/modules/${KERNEL_VER}/kernel/drivers/bus
rm -rf lib/modules/${KERNEL_VER}/kernel/block
rm -rf lib/modules/${KERNEL_VER}/kernel/lib/lz4
rm -rf lib/modules/${KERNEL_VER}/kernel/lib/crypto

rm -f lib/modules/${KERNEL_VER}/modules.alias.new
rm -f lib/modules/${KERNEL_VER}/modules.dep.new
rm -f lib/modules/${KERNEL_VER}/modules.order.new

for i in $(grep -v "^#" lib/modules/${KERNEL_VER}/modules.alias | cut -d ' ' -f 3- | sort | uniq)
do
    if [ -n "$(find . -name "$i.ko")" ]
    then
        grep " $i" lib/modules/${KERNEL_VER}/modules.alias >> lib/modules/${KERNEL_VER}/modules.alias.new
    fi
done

mv lib/modules/${KERNEL_VER}/modules.alias.new lib/modules/${KERNEL_VER}/modules.alias

for i in $(cat lib/modules/${KERNEL_VER}/modules.dep | cut -d ':' -f 1)
do
    if [ -f lib/modules/${KERNEL_VER}/$i ]
    then
        grep "$i:" lib/modules/${KERNEL_VER}/modules.dep >> lib/modules/${KERNEL_VER}/modules.dep.new
    fi
done

mv lib/modules/${KERNEL_VER}/modules.dep.new lib/modules/${KERNEL_VER}/modules.dep

for i in $(cat lib/modules/${KERNEL_VER}/modules.order)
do
    if [ -f lib/modules/${KERNEL_VER}/$i ]
    then
        grep "$i" lib/modules/${KERNEL_VER}/modules.order >> lib/modules/${KERNEL_VER}/modules.order.new
    fi
done

mv lib/modules/${KERNEL_VER}/modules.order.new lib/modules/${KERNEL_VER}/modules.order


cat << EOF > init
#!/bin/sh

ZRAM_SIZE="64M"
rescue()
{
    echo "Dropping to rescue shell"
    /bin/busybox sh
    exit
}
checkedmp()
{
    modprobe \$1 || { echo "failed to find \$1 module"; rescue; }
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
checkedmp zram
checkedmp squashfs
checkedmp overlay
checkedmp cdrom
checkedmp sr_mod
checkedmp isofs
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

#find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > "${DIST_DISK}/isolinux/initrd.gz"
find . -print0 | cpio --null --create --verbose --format=newc | xz --check=crc32 > "${DIST_DISK}/isolinux/initrd.xz"

cd "${OLD_PWD}"
