#!/bin/sh

set -ex
export DIST_BUILD="build"
rm -rf "${DIST_BUILD}"
mkdir -p "${DIST_BUILD}"
export DIST_ROOT="$(realpath "${DIST_BUILD}/root")"
export DIST_INITRD="$(realpath "${DIST_BUILD}/initrd")"
export DIST_DISK="$(realpath "${DIST_BUILD}/disk")"
export DIST_ISO="${DIST_BUILD}/486lin.iso"
export DIST_SQUASHFS="${DIST_DISK}/root.sfs"

DIST_DIRS="bin boot dev etc home lib mnt proc root run sbin sys tmp var etc/init.d"
rm -rf "${DIST_ROOT}"
rm -rf "${DIST_INITRD}"
rm -rf "${DIST_DISK}"
mkdir -p "${DIST_ROOT}"
mkdir -p "${DIST_INITRD}"
mkdir -p "${DIST_DISK}"
for dir in ${DIST_DIRS}
do
    mkdir -p "${DIST_ROOT}/${dir}"
    mkdir -p "${DIST_INITRD}/${dir}"
done

export LINUX_URL="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
export LINUX_BRANCH="linux-6.1.y"
export LINUX_DIR="linux"

./build_linux.sh

export MUSL_URL="git://git.musl-libc.org/musl"
export MUSL_TAG="v1.2.5"
export MUSL_DIR="musl"
export MUSL_INSTALL_PATH="$(realpath "${MUSL_DIR}/install")"
export MUSL_BIN="${MUSL_INSTALL_PATH}/bin"
MUSL_LIB="${MUSL_INSTALL_PATH}/lib"
MUSL_INC="${MUSL_INSTALL_PATH}/include"

./build_musl.sh

export BUSYBOX_URL="git://git.busybox.net/busybox"
export BUSYBOX_BRANCH="1_37_stable"
export BUSYBOX_DIR="busybox"
export BUSYBOX_EXE="$(realpath ${BUSYBOX_DIR}/busybox)"

./build_busybox.sh
./create_initrd.sh
SYSLINUX_VER="6.03"
export SYSLINUX_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VER}.tar.gz"
export SYSLINUX_DIR="syslinux"

if [ ! -d "${SYSLINUX_DIR}" ]
then
    wget "${SYSLINUX_URL}"
    tar xvf syslinux-${SYSLINUX_VER}.tar.gz
    mv syslinux-${SYSLINUX_VER} syslinux
fi
OLD_PWD="${PWD}"
mkdir -p "${DIST_DISK}/isolinux"
cp "${SYSLINUX_DIR}/bios/core/isolinux.bin" "${DIST_DISK}/isolinux"
cp "${SYSLINUX_DIR}/bios/com32/elflink/ldlinux/ldlinux.c32" "${DIST_DISK}/isolinux"
cat << EOF > "${DIST_DISK}/isolinux/isolinux.cfg"
TIMEOUT 30
DEFAULT 486LIN
LABEL 486LIN
    LINUX vmlinuz
    INITRD initrd.gz
EOF
rm -rf "${DIST_SQUASHFS}"
mksquashfs "${DIST_ROOT}" "${DIST_SQUASHFS}" -comp gzip
rm -rf "${DIST_ISO}"
mkisofs -o "${DIST_ISO}" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        "${DIST_DISK}"

HARD_DISK="486_hdd.img"
DISK_SIZE="8G"
RAM_SIZE=32

PLOP_VER="5.15.0"
PLOP_DIR="plpbt-${PLOP_VER}"
PLOP_ZIP_FILE="${PLOP_DIR}.zip"
PLOP_URL="https://download.plop.at/files/bootmngr/${PLOP_ZIP_FILE}"
PLOP_CFG_DIR="Linux"
PLOP_CFG="./plpcfgbt"
PLOP_IMG="plpbt.img"
PLOP_CFG_PATH="${PLOP_DIR}/${PLOP_CFG_DIR}/${PLOP_CFG}"
PLOP_CFG_ARGS="vm=text stf=off dbt=cdrom cnt=on cntval=15"
PLOP_IMG_PATH="${PLOP_DIR}/${PLOP_IMG}"
PLOP_LB_DIR="plopbt-lb"
PLOP_CFG_BIN="plpbt.bin"
PLOP_CFG_TARGET="${PLOP_LB_DIR}/${PLOP_CFG_BIN}"

if [ ! -f "${HARD_DISK}" ]
then
    qemu-img create -f qcow2 "${HARD_DISK}" "${DISK_SIZE}"
fi

if [ ! -f "${PLOP_CFG}" ] || [ ! -f "${PLOP_IMG}" ]
then
    if [ ! -d "${PLOP_DIR}" ]
    then
        if [ ! -f "${PLOP_ZIP_FILE}" ]
        then
            wget "${PLOP_URL}" -O "${PLOP_ZIP_FILE}"
        fi
        unzip "${PLOP_ZIP_FILE}" && rm "${PLOP_ZIP_FILE}"
    fi
    cp "${PLOP_CFG_PATH}" "${PLOP_CFG}"
    cp "${PLOP_IMG_PATH}" "${PLOP_IMG}"
    rm -rf "${PLOP_DIR}"
fi

mkdir -p "${PLOP_LB_DIR}"
if mount | grep -q "$(realpath "${PLOP_LB_DIR}")"
then
    sudo umount "${PLOP_LB_DIR}"
fi
sudo mount "${PLOP_IMG}" "${PLOP_LB_DIR}"
sudo "${PLOP_CFG}" ${PLOP_CFG_ARGS} "${PLOP_CFG_TARGET}"
sudo umount "${PLOP_LB_DIR}" && rmdir "${PLOP_LB_DIR}"

qemu-system-i386 \
    -cpu 486 \
    -m "${RAM_SIZE}" \
    -drive if=ide,file="${HARD_DISK}",index=0,media=disk,driver=qcow2 \
    -drive if=floppy,file="${PLOP_IMG}",index=0,media=disk,driver=raw \
    -drive if=ide,file="${DIST_ISO}",index=1,media=cdrom
