#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

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
    echo "Cleaning Busybox (initrd) build..."
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    rm -f "${BUSYBOX_CONFIG_PATH}"
    make mrproper
    cd "${OLD_PWD}"
fi

if [ "${CONFIGURE_BUSYBOX}" -eq 1 ]
then
    echo "Configuring Busybox for initrd..."
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    make allnoconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "INSTALL_NO_USR" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "LS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "LFS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "TIME64" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "BUSYBOX" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_INSTALLER" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "STATIC" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "STATIC_LIBGCC" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MD5_SMALL" "3"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_USE_SENDFILE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MONOTONIC_SYSCALL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_PRESERVE_HARDLINKS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "CAT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "CP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_CP_REFLINK" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "CUT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "REALPATH" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "RM" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "RMDIR" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SEQ" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SLEEP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_FANCY_SLEEP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SORT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_SORT_BIG" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_SORT_OPTIMIZE_MEMORY" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SYNC" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_SYNC_FANCY" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "TAIL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_FANCY_TAIL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "TEE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_TEE_USE_BLOCK_IO" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "TEST" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "TEST1" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_TEST_64" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "TOUCH" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "UNIQ" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "GREP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "XARGS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_XARGS_SUPPORT_QUOTES" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MODPROBE_SMALL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "INSMOD" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "LSMOD" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MODPROBE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "RMMOD" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_CMDLINE_MODULE_OPTIONS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MODPROBE_SMALL_CHECK_ALREADY_LOADED" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "DEFAULT_MODULES_DIR" "\"/lib/modules\""
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "DEFAULT_DEPMOD_FILE" "\"modules.dep\""
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "LOSETUP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MKE2FS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MKFS_EXT2" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MKSWAP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MOUNT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_FAKE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_VERBOSE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_HELPERS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_LABEL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_FLAGS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_FSTAB" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SWAPON" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_SWAPON_DISCARD" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_SWAPON_PRI" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SWAPOFF" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_SWAPONOFF_LABEL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "SWITCH_ROOT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "UMOUNT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_UMOUNT_ALL" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_LOOP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_MOUNT_LOOP_CREATE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "VOLUMEID" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_CRAMFS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_EXT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_FAT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_ISO9660" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_LINUXSWAP" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_LUKS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_ROMFS" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "FEATURE_VOLUMEID_UDF" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_OPTIMIZE_FOR_SIZE" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_INTERNAL_GLOB" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_BASH_COMPAT" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_ECHO" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_PRINTF" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_TEST" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "ASH_CMDCMD" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "MKDIR" "y"
    set_kbuild_config_val "${BUSYBOX_CONFIG_PATH}" "EXPR" "y"
    make oldconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
    cd "${OLD_PWD}"
fi

echo "Done"

