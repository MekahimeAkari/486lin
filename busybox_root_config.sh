#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPT_DIR}/${COMMON_FUNCS_NAME}"

BUSYBOX_CC_LINE="gcc"
BUSYBOX_CONFIG_NAME=".config"

busybox_root_config_help()
{
cat << EOF
Busybox config script for / for 486lin

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
            busybox_config_root_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            busybox_config_root_help
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
    busybox_config_root_help
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
    make defconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' "${BUSYBOX_CONFIG_PATH}"
    sed -i 's/# CONFIG_INSTALL_NO_USR is not set/CONFIG_INSTALL_NO_USR=y/' "${BUSYBOX_CONFIG_PATH}"
    make oldconfig HOSTCC="${BUSYBOX_CC_LINE}" CC="${BUSYBOX_CC_LINE}"
    cd "${OLD_PWD}"
fi

