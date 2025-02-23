#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPT_DIR}/${COMMON_FUNCS_NAME}"

BUSYBOX_CC_LINE="gcc"
BUSYBOX_CONFIG_NAME=".config"

busybox_initrd_config_help()
{
cat << EOF
Busybox config script for initrd for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean] | [dist-clean-build] [no-nuke] [BUSYBOX_PATH=<PATH>] [BUSYBOX_CC_LINE=<LINE>]

Arguments:
clean|dist-clean: Clean up working directory and quit (default: Don't quit)
dist-clean-build: Clean up and build (is the default, here for ease of use)
no-nuke: Don't nuke already built objects (default: do nuke them)

BUSYBOX_PATH=<PATH>: PATH to the Busybox source repo (required)
BUSYBOX_CC_LINE=<LINE>: PATH to complier to use for Busybox (default '${BUSYBOX_CC_LINE}')
EOF
}

set -x

CLEAN_BUILD=1
CONFIGURE_BUSYBOX=1
DO_WORK=1

while [ $# -gt 0 ]
do
    case $1 in
        no-nuke)
            CLEAN_BUILD=0
            shift
            ;;
        dist-clean-build)
            CLEAN_BUILD=1
            CONFIGURE_BUSYBOX=1
            DO_WORK=1
            shift
            ;;
        clean|dist-clean)
            CLEAN_BUILD=1
            CONFIGURE_BUSYBOX=0
            DO_WORK=0
            shift
            ;;
        BUSYBOX_PATH=*)
            BUSYBOX_PATH="$(get_var_val "$1")"
            shift
            ;;
        BUSYBOX_CC_LINE=*)
            BUSYBOX_CC_LINE="$(get_var_val "$1")"
            shift
            ;;
        help|-h|--help)
            busybox_initrd_config_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            busybox_initrd_config_help
            exit 1
            ;;
    esac
done

EXIT_HELP=0

if [ -z "${BUSYBOX_PATH}" ]
then
    echo "\$BUSYBOX_PATH is required to be defined"
    EXIT_HELP=1
fi


if [ "${EXIT_HELP}" -eq 1 ]
then
    busybox_initrd_config_help
    exit 1
fi

BUSYBOX_CONFIG_PATH="${BUSYBOX_PATH}/${BUSYBOX_CONFIG_NAME}"

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    rm -f "${BUSYBOX_CONFIG_PATH}"
    make mrproper
    cd "${OLD_PWD}"
fi

if [ "${CONFIGURE_BUSYBOX}" -eq 1 ]
then
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    make allnoconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
    sed -i 's/# CONFIG_LS is not set/CONFIG_LS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_LFS is not set/CONFIG_LFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_TIME64 is not set/CONFIG_TIME64=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_BUSYBOX is not set/CONFIG_BUSYBOX=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_INSTALLER is not set/CONFIG_FEATURE_INSTALLER=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_STATIC_LIBGCC is not set/CONFIG_STATIC_LIBGCC=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/CONFIG_MD5_SMALL=1/CONFIG_MD5_SMALL=3/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_USE_SENDFILE is not set/CONFIG_FEATURE_USE_SENDFILE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MONOTONIC_SYSCALL is not set/CONFIG_MONOTONIC_SYSCALL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_PRESERVE_HARDLINKS is not set/CONFIG_FEATURE_PRESERVE_HARDLINKS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_CAT is not set/CONFIG_CAT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_CP is not set/CONFIG_CP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_CP_LONG_OPTIONS is not set/CONFIG_FEATURE_CP_LONG_OPTIONS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_CP_REFLINK is not set/CONFIG_FEATURE_CP_REFLINK=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_CUT is not set/CONFIG_CUT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_REALPATH is not set/CONFIG_REALPATH=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_RM is not set/CONFIG_RM=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_RMDIR is not set/CONFIG_RMDIR=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SEQ is not set/CONFIG_SEQ=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SLEEP is not set/CONFIG_SLEEP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_FANCY_SLEEP is not set/CONFIG_FEATURE_FANCY_SLEEP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SORT is not set/CONFIG_SORT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_SORT_BIG is not set/CONFIG_FEATURE_SORT_BIG=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_SORT_OPTIMIZE_MEMORY is not set/CONFIG_FEATURE_SORT_OPTIMIZE_MEMORY=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SYNC is not set/CONFIG_SYNC=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_SYNC_FANCY is not set/CONFIG_FEATURE_SYNC_FANCY=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_TAIL is not set/CONFIG_TAIL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_FANCY_TAIL is not set/CONFIG_FEATURE_FANCY_TAIL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_TEE is not set/CONFIG_TEE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_TEE_USE_BLOCK_IO is not set/CONFIG_FEATURE_TEE_USE_BLOCK_IO=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_TEST is not set/CONFIG_TEST=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_TEST1 is not set/CONFIG_TEST1=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_TEST_64 is not set/CONFIG_FEATURE_TEST_64=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_TOUCH is not set/CONFIG_TOUCH=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_UNIQ is not set/CONFIG_UNIQ=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_GREP is not set/CONFIG_GREP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_XARGS is not set/CONFIG_XARGS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_XARGS_SUPPORT_QUOTES is not set/CONFIG_FEATURE_XARGS_SUPPORT_QUOTES=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MODPROBE_SMALL is not set/CONFIG_MODPROBE_SMALL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_INSMOD is not set/CONFIG_INSMOD=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_LSMOD is not set/CONFIG_LSMOD=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MODPROBE is not set/CONFIG_MODPROBE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_RMMOD is not set/CONFIG_RMMOD=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_CMDLINE_MODULE_OPTIONS is not set/CONFIG_FEATURE_CMDLINE_MODULE_OPTIONS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MODPROBE_SMALL_CHECK_ALREADY_LOADED is not s/CONFIG_FEATURE_MODPROBE_SMALL_CHECK_ALREADY_LOADED=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/CONFIG_DEFAULT_MODULES_DIR=""/CONFIG_DEFAULT_MODULES_DIR="\/lib\/modules"/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/CONFIG_DEFAULT_DEPMOD_FILE=""/CONFIG_DEFAULT_DEPMOD_FILE="modules.dep"/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_LOSETUP is not set/CONFIG_LOSETUP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MKE2FS is not set/CONFIG_MKE2FS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MKFS_EXT2 is not set/CONFIG_MKFS_EXT2=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MOUNT is not set/CONFIG_MOUNT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_FAKE is not set/CONFIG_FEATURE_MOUNT_FAKE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_VERBOSE is not set/CONFIG_FEATURE_MOUNT_VERBOSE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_HELPERS is not set/CONFIG_FEATURE_MOUNT_HELPERS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_LABEL is not set/CONFIG_FEATURE_MOUNT_LABEL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_CIFS is not set/CONFIG_FEATURE_MOUNT_CIFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_FLAGS is not set/CONFIG_FEATURE_MOUNT_FLAGS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_FSTAB is not set/CONFIG_FEATURE_MOUNT_FSTAB=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_OTHERTAB is not set/CONFIG_FEATURE_MOUNT_OTHERTAB=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SWAPON is not set/CONFIG_SWAPON=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_SWAPON_DISCARD is not set/CONFIG_FEATURE_SWAPON_DISCARD=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_SWAPON_PRI is not set/CONFIG_FEATURE_SWAPON_PRI=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SWAPOFF is not set/CONFIG_SWAPOFF=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_SWAPONOFF_LABEL is not set/CONFIG_FEATURE_SWAPONOFF_LABEL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_SWITCH_ROOT is not set/CONFIG_SWITCH_ROOT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_UMOUNT is not set/CONFIG_UMOUNT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_UMOUNT_ALL is not set/CONFIG_FEATURE_UMOUNT_ALL=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_LOOP is not set/CONFIG_FEATURE_MOUNT_LOOP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_MOUNT_LOOP_CREATE is not set/CONFIG_FEATURE_MOUNT_LOOP_CREATE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_VOLUMEID is not set/CONFIG_VOLUMEID=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_BCACHE is not set/CONFIG_FEATURE_VOLUMEID_BCACHE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_BTRFS is not set/CONFIG_FEATURE_VOLUMEID_BTRFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_CRAMFS is not set/CONFIG_FEATURE_VOLUMEID_CRAMFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_EROFS is not set/CONFIG_FEATURE_VOLUMEID_EROFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_EXFAT is not set/CONFIG_FEATURE_VOLUMEID_EXFAT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_EXT is not set/CONFIG_FEATURE_VOLUMEID_EXT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_F2FS is not set/CONFIG_FEATURE_VOLUMEID_F2FS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_FAT is not set/CONFIG_FEATURE_VOLUMEID_FAT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_HFS is not set/CONFIG_FEATURE_VOLUMEID_HFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_ISO9660 is not set/CONFIG_FEATURE_VOLUMEID_ISO9660=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_JFS is not set/CONFIG_FEATURE_VOLUMEID_JFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_LINUXRAID is not set/CONFIG_FEATURE_VOLUMEID_LINUXRAID=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_LINUXSWAP is not set/CONFIG_FEATURE_VOLUMEID_LINUXSWAP=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_LUKS is not set/CONFIG_FEATURE_VOLUMEID_LUKS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_MINIX is not set/CONFIG_FEATURE_VOLUMEID_MINIX=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_NILFS is not set/CONFIG_FEATURE_VOLUMEID_NILFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_NTFS is not set/CONFIG_FEATURE_VOLUMEID_NTFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_OCFS2 is not set/CONFIG_FEATURE_VOLUMEID_OCFS2=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_REISERFS is not set/CONFIG_FEATURE_VOLUMEID_REISERFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_ROMFS is not set/CONFIG_FEATURE_VOLUMEID_ROMFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_SYSV is not set/CONFIG_FEATURE_VOLUMEID_SYSV=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_UBIFS is not set/CONFIG_FEATURE_VOLUMEID_UBIFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_UDF is not set/CONFIG_FEATURE_VOLUMEID_UDF=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_FEATURE_VOLUMEID_XFS is not set/CONFIG_FEATURE_VOLUMEID_XFS=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH is not set/CONFIG_ASH=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_OPTIMIZE_FOR_SIZE is not set/CONFIG_ASH_OPTIMIZE_FOR_SIZE=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_INTERNAL_GLOB is not set/CONFIG_ASH_INTERNAL_GLOB=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_BASH_COMPAT is not set/CONFIG_ASH_BASH_COMPAT=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_ECHO is not set/CONFIG_ASH_ECHO=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_PRINTF is not set/CONFIG_ASH_PRINTF=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_TEST is not set/CONFIG_ASH_TEST=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_ASH_CMDCMD is not set/CONFIG_ASH_CMDCMD=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_MKDIR is not set/CONFIG_MKDIR=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_EXPR is not set/CONFIG_EXPR=y/' "${BUSYBOX_CONFIG_PATH}"
    make oldconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
    cd "${OLD_PWD}"
fi

