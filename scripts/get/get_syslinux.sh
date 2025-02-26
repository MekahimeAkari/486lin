#!/bin/sh
set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

SYSLINUX_VER="6.03"
SYSLINUX_EXT="tar.gz"
SYSLINUX_ARCHIVE="syslinux.${SYSLINUX_EXT}"
SYSLINUX_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VER}.${SYSLINUX_EXT}"

get_syslinux_help()
{
cat << EOF
Syslinux getting script for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean] | [dist-clean-build] [no-nuke] [SYSLINUX_PATH=<PATH>]

Arguments:
clean|dist-clean: Clean up working directory and quit (default: Don't quit)
dist-clean-build: Clean up and build (is the default, here for ease of use)
no-nuke: Don't nuke already built objects (default: do nuke them)

SYSLINUX_PATH=<PATH>: PATH to output Syslinux binaries (required)
EOF
}

CLEAN_BUILD=0
GET_SYSLINUX=1
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
            GET_SYSLINUX=1
            DO_WORK=1
            shift
            ;;
        clean|dist-clean)
            CLEAN_BUILD=1
            GET_SYSLINUX=0
            DO_WORK=0
            shift
            ;;
        SYSLINUX_PATH=*)
            SYSLINUX_PATH="$(get_var_val "$1")"
            shift
            ;;
        help|-h|--help)
            get_syslinux_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            get_syslinux_help
            exit 1
            ;;
    esac
done

EXIT_HELP=0

if [ -z "${SYSLINUX_PATH}" ]
then
    echo "\$SYSLINUX_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    get_syslinux_help
    exit 1
fi

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    echo "Cleaning Syslinux..."
    rm -rf "${SYSLINUX_ARCHIVE}"
    rm -rf "${SYSLINUX_PATH}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi

if [ "${GET_SYSLINUX}" -eq 1 ]
then
    echo "Getting Syslinux..."
    if [ ! -d "${SYSLINUX_PATH}" ]
    then
        if [ ! -f "${SYSLINUX_ARCHIVE}" ]
        then
            wget "${SYSLINUX_URL}" -O "${SYSLINUX_ARCHIVE}"
        fi
        mkdir -p "${SYSLINUX_PATH}"
        tar xvf "${SYSLINUX_ARCHIVE}" -C "${SYSLINUX_PATH}" --strip-components=1
    fi
    OLD_PWD="${PWD}"
    cd "${OLD_PWD}"
fi

echo "Done"
