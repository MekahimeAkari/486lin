#!/bin/sh

if [ -z "${DIST_INITRD}" ]
then
    echo "\$DIST_INITRD not defined"
    exit 1
fi
if [ -z "${BUSYBOX_URL}" ]
then
    echo "\$BUSYBOX_URL not defined"
    exit 1
fi
if [ -z "${BUSYBOX_DIR}" ]
then
    echo "\$BUSYBOX_DIR not defined"
    exit 1
fi
if [ -z "${BUSYBOX_BRANCH}" ]
then
    echo "\$BUSYBOX_BRANCH not defined"
    exit 1
fi
if [ -z "${MUSL_BIN}" ]
then
    echo "\$MUSL_BIN not defined"
    exit 1
fi
if [ -z "${LINUX_DIR}" ]
then
    echo "\$LINUX_DIR not defined"
    exit 1
fi

BUSYBOX_CC="$(realpath ${MUSL_BIN}/musl-gcc)"
BUSYBOX_CFLAGS="-m32 -march=i486 -Wl,-m -Wl,elf_i386 -static -static-libgcc -I$(realpath ${LINUX_DIR}/install/include)"
BUSYBOX_CC_LINE="${BUSYBOX_CC} ${BUSYBOX_CFLAGS}"

if [ ! -d "${BUSYBOX_DIR}" ]
then
    git clone "${BUSYBOX_URL}" "${BUSYBOX_DIR}"
fi
OLD_PWD="${PWD}"
cd "${BUSYBOX_DIR}"
git stash
git checkout "${BUSYBOX_BRANCH}"
git pull --rebase
git stash pop || true
sed -i 's/^main()/int main()/' scripts/kconfig/lxdialog/check-lxdialog.sh
if ! grep -q "#ifndef TCA_CBQ_MAX" "networking/tc.c"
then
    git apply ../tca_cbq_removed.patch
fi
make mrproper
NPROC="$(nproc)"
if [ -z "${NPROC}" ]
then
    NPROC=2
fi
cp ../.config .
make defconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/# CONFIG_INSTALL_NO_USR is not set/CONFIG_INSTALL_NO_USR=y/' .config
make install -j${NPROC} HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}" CONFIG_PREFIX="${DIST_INITRD}"
make install -j${NPROC} HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}" CONFIG_PREFIX="${DIST_ROOT}"
