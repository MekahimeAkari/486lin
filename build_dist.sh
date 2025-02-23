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
export MUSL_INSTALL_DIR="install"

./build_musl.sh

export MUSL_INSTALL_PATH="$(realpath ${MUSL_DIR}/${MUSL_INSTALL_DIR})"
export MUSL_BIN="${MUSL_INSTALL_PATH}/bin"
export BUSYBOX_URL="git://git.busybox.net/busybox"
export BUSYBOX_BRANCH="1_37_stable"
export BUSYBOX_DIR="busybox"

./build_busybox.sh

export BUSYBOX_EXE="$(realpath ${BUSYBOX_DIR}/busybox)"
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
    INITRD initrd.xz
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
