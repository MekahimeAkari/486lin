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
make defconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/# CONFIG_INSTALL_NO_USR is not set/CONFIG_INSTALL_NO_USR=y/' .config
make install -j${NPROC} HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}" CONFIG_PREFIX="${DIST_ROOT}"
make mrproper
make allnoconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
sed -i 's/# CONFIG_LONG_OPTS is not set/CONFIG_LONG_OPTS=y/' .config
sed -i 's/# CONFIG_LFS is not set/CONFIG_LFS=y/' .config
sed -i 's/# CONFIG_TIME64 is not set/CONFIG_TIME64=y/' .config
sed -i 's/# CONFIG_BUSYBOX is not set/CONFIG_BUSYBOX=y/' .config
sed -i 's/# CONFIG_FEATURE_INSTALLER is not set/CONFIG_FEATURE_INSTALLER=y/' .config
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/# CONFIG_STATIC_LIBGCC is not set/CONFIG_STATIC_LIBGCC=y/' .config
sed -i 's/CONFIG_MD5_SMALL=1/CONFIG_MD5_SMALL=3/' .config
sed -i 's/# CONFIG_FEATURE_USE_SENDFILE is not set/CONFIG_FEATURE_USE_SENDFILE=y/' .config
sed -i 's/# CONFIG_MONOTONIC_SYSCALL is not set/CONFIG_MONOTONIC_SYSCALL=y/' .config
sed -i 's/# CONFIG_FEATURE_PRESERVE_HARDLINKS is not set/CONFIG_FEATURE_PRESERVE_HARDLINKS=y/' .config
sed -i 's/# CONFIG_CAT is not set/CONFIG_CAT=y/' .config
sed -i 's/# CONFIG_CP is not set/CONFIG_CP=y/' .config
sed -i 's/# CONFIG_FEATURE_CP_LONG_OPTIONS is not set/CONFIG_FEATURE_CP_LONG_OPTIONS=y/' .config
sed -i 's/# CONFIG_FEATURE_CP_REFLINK is not set/CONFIG_FEATURE_CP_REFLINK=y/' .config
sed -i 's/# CONFIG_CUT is not set/CONFIG_CUT=y/' .config
sed -i 's/# CONFIG_REALPATH is not set/CONFIG_REALPATH=y/' .config
sed -i 's/# CONFIG_RM is not set/CONFIG_RM=y/' .config
sed -i 's/# CONFIG_RMDIR is not set/CONFIG_RMDIR=y/' .config
sed -i 's/# CONFIG_SEQ is not set/CONFIG_SEQ=y/' .config
sed -i 's/# CONFIG_SLEEP is not set/CONFIG_SLEEP=y/' .config
sed -i 's/# CONFIG_FEATURE_FANCY_SLEEP is not set/CONFIG_FEATURE_FANCY_SLEEP=y/' .config
sed -i 's/# CONFIG_SORT is not set/CONFIG_SORT=y/' .config
sed -i 's/# CONFIG_FEATURE_SORT_BIG is not set/CONFIG_FEATURE_SORT_BIG=y/' .config
sed -i 's/# CONFIG_FEATURE_SORT_OPTIMIZE_MEMORY is not set/CONFIG_FEATURE_SORT_OPTIMIZE_MEMORY=y/' .config
sed -i 's/# CONFIG_SYNC is not set/CONFIG_SYNC=y/' .config
sed -i 's/# CONFIG_FEATURE_SYNC_FANCY is not set/CONFIG_FEATURE_SYNC_FANCY=y/' .config
sed -i 's/# CONFIG_TAIL is not set/CONFIG_TAIL=y/' .config
sed -i 's/# CONFIG_FEATURE_FANCY_TAIL is not set/CONFIG_FEATURE_FANCY_TAIL=y/' .config
sed -i 's/# CONFIG_TEE is not set/CONFIG_TEE=y/' .config
sed -i 's/# CONFIG_FEATURE_TEE_USE_BLOCK_IO is not set/CONFIG_FEATURE_TEE_USE_BLOCK_IO=y/' .config
sed -i 's/# CONFIG_TEST is not set/CONFIG_TEST=y/' .config
sed -i 's/# CONFIG_TEST1 is not set/CONFIG_TEST1=y/' .config
sed -i 's/# CONFIG_FEATURE_TEST_64 is not set/CONFIG_FEATURE_TEST_64=y/' .config
sed -i 's/# CONFIG_TOUCH is not set/CONFIG_TOUCH=y/' .config
sed -i 's/# CONFIG_UNIQ is not set/CONFIG_UNIQ=y/' .config
sed -i 's/# CONFIG_GREP is not set/CONFIG_GREP=y/' .config
sed -i 's/# CONFIG_XARGS is not set/CONFIG_XARGS=y/' .config
sed -i 's/# CONFIG_FEATURE_XARGS_SUPPORT_QUOTES is not set/CONFIG_FEATURE_XARGS_SUPPORT_QUOTES=y/' .config
sed -i 's/# CONFIG_MODPROBE_SMALL is not set/CONFIG_MODPROBE_SMALL=y/' .config
sed -i 's/# CONFIG_INSMOD is not set/CONFIG_INSMOD=y/' .config
sed -i 's/# CONFIG_LSMOD is not set/CONFIG_LSMOD=y/' .config
sed -i 's/# CONFIG_MODPROBE is not set/CONFIG_MODPROBE=y/' .config
sed -i 's/# CONFIG_RMMOD is not set/CONFIG_RMMOD=y/' .config
sed -i 's/# CONFIG_FEATURE_CMDLINE_MODULE_OPTIONS is not set/CONFIG_FEATURE_CMDLINE_MODULE_OPTIONS=y/' .config
sed -i 's/# CONFIG_FEATURE_MODPROBE_SMALL_CHECK_ALREADY_LOADED is not s/CONFIG_FEATURE_MODPROBE_SMALL_CHECK_ALREADY_LOADED=y/' .config
sed -i 's/CONFIG_DEFAULT_MODULES_DIR=""/CONFIG_DEFAULT_MODULES_DIR="\/lib\/modules"/' .config
sed -i 's/CONFIG_DEFAULT_DEPMOD_FILE=""/CONFIG_DEFAULT_DEPMOD_FILE="modules.dep"/' .config
sed -i 's/# CONFIG_LOSETUP is not set/CONFIG_LOSETUP=y/' .config
sed -i 's/# CONFIG_MKE2FS is not set/CONFIG_MKE2FS=y/' .config
sed -i 's/# CONFIG_MKFS_EXT2 is not set/CONFIG_MKFS_EXT2=y/' .config
sed -i 's/# CONFIG_MOUNT is not set/CONFIG_MOUNT=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_FAKE is not set/CONFIG_FEATURE_MOUNT_FAKE=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_VERBOSE is not set/CONFIG_FEATURE_MOUNT_VERBOSE=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_HELPERS is not set/CONFIG_FEATURE_MOUNT_HELPERS=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_LABEL is not set/CONFIG_FEATURE_MOUNT_LABEL=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_CIFS is not set/CONFIG_FEATURE_MOUNT_CIFS=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_FLAGS is not set/CONFIG_FEATURE_MOUNT_FLAGS=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_FSTAB is not set/CONFIG_FEATURE_MOUNT_FSTAB=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_OTHERTAB is not set/CONFIG_FEATURE_MOUNT_OTHERTAB=y/' .config
sed -i 's/# CONFIG_SWAPON is not set/CONFIG_SWAPON=y/' .config
sed -i 's/# CONFIG_FEATURE_SWAPON_DISCARD is not set/CONFIG_FEATURE_SWAPON_DISCARD=y/' .config
sed -i 's/# CONFIG_FEATURE_SWAPON_PRI is not set/CONFIG_FEATURE_SWAPON_PRI=y/' .config
sed -i 's/# CONFIG_SWAPOFF is not set/CONFIG_SWAPOFF=y/' .config
sed -i 's/# CONFIG_FEATURE_SWAPONOFF_LABEL is not set/CONFIG_FEATURE_SWAPONOFF_LABEL=y/' .config
sed -i 's/# CONFIG_SWITCH_ROOT is not set/CONFIG_SWITCH_ROOT=y/' .config
sed -i 's/# CONFIG_UMOUNT is not set/CONFIG_UMOUNT=y/' .config
sed -i 's/# CONFIG_FEATURE_UMOUNT_ALL is not set/CONFIG_FEATURE_UMOUNT_ALL=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_LOOP is not set/CONFIG_FEATURE_MOUNT_LOOP=y/' .config
sed -i 's/# CONFIG_FEATURE_MOUNT_LOOP_CREATE is not set/CONFIG_FEATURE_MOUNT_LOOP_CREATE=y/' .config
sed -i 's/# CONFIG_VOLUMEID is not set/CONFIG_VOLUMEID=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_BCACHE is not set/CONFIG_FEATURE_VOLUMEID_BCACHE=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_BTRFS is not set/CONFIG_FEATURE_VOLUMEID_BTRFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_CRAMFS is not set/CONFIG_FEATURE_VOLUMEID_CRAMFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_EROFS is not set/CONFIG_FEATURE_VOLUMEID_EROFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_EXFAT is not set/CONFIG_FEATURE_VOLUMEID_EXFAT=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_EXT is not set/CONFIG_FEATURE_VOLUMEID_EXT=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_F2FS is not set/CONFIG_FEATURE_VOLUMEID_F2FS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_FAT is not set/CONFIG_FEATURE_VOLUMEID_FAT=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_HFS is not set/CONFIG_FEATURE_VOLUMEID_HFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_ISO9660 is not set/CONFIG_FEATURE_VOLUMEID_ISO9660=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_JFS is not set/CONFIG_FEATURE_VOLUMEID_JFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_LINUXRAID is not set/CONFIG_FEATURE_VOLUMEID_LINUXRAID=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_LINUXSWAP is not set/CONFIG_FEATURE_VOLUMEID_LINUXSWAP=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_LUKS is not set/CONFIG_FEATURE_VOLUMEID_LUKS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_MINIX is not set/CONFIG_FEATURE_VOLUMEID_MINIX=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_NILFS is not set/CONFIG_FEATURE_VOLUMEID_NILFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_NTFS is not set/CONFIG_FEATURE_VOLUMEID_NTFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_OCFS2 is not set/CONFIG_FEATURE_VOLUMEID_OCFS2=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_REISERFS is not set/CONFIG_FEATURE_VOLUMEID_REISERFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_ROMFS is not set/CONFIG_FEATURE_VOLUMEID_ROMFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_SYSV is not set/CONFIG_FEATURE_VOLUMEID_SYSV=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_UBIFS is not set/CONFIG_FEATURE_VOLUMEID_UBIFS=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_UDF is not set/CONFIG_FEATURE_VOLUMEID_UDF=y/' .config
sed -i 's/# CONFIG_FEATURE_VOLUMEID_XFS is not set/CONFIG_FEATURE_VOLUMEID_XFS=y/' .config
sed -i 's/# CONFIG_ASH is not set/CONFIG_ASH=y/' .config
sed -i 's/# CONFIG_ASH_OPTIMIZE_FOR_SIZE is not set/CONFIG_ASH_OPTIMIZE_FOR_SIZE=y/' .config
sed -i 's/# CONFIG_ASH_INTERNAL_GLOB is not set/CONFIG_ASH_INTERNAL_GLOB=y/' .config
sed -i 's/# CONFIG_ASH_BASH_COMPAT is not set/CONFIG_ASH_BASH_COMPAT=y/' .config
sed -i 's/# CONFIG_ASH_ALIAS is not set/CONFIG_ASH_ALIAS=y/' .config
sed -i 's/# CONFIG_ASH_ECHO is not set/CONFIG_ASH_ECHO=y/' .config
sed -i 's/# CONFIG_ASH_PRINTF is not set/CONFIG_ASH_PRINTF=y/' .config
sed -i 's/# CONFIG_ASH_TEST is not set/CONFIG_ASH_TEST=y/' .config
sed -i 's/# CONFIG_ASH_CMDCMD is not set/CONFIG_ASH_CMDCMD=y/' .config
sed -i 's/# CONFIG_CTTYHACK is not set/CONFIG_CTTYHACK=y/' .config
sed -i 's/# CONFIG_MKDIR is not set/CONFIG_MKDIR=y/' .config
make install -j${NPROC} HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}" CONFIG_PREFIX="${DIST_INITRD}"
