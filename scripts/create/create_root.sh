#!/bin/sh
set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

MODULES_DIR="lib/modules"

create_initrd_help()
{
cat << EOF
Live root create script for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean] | [dist-clean-build] [no-nuke] [ROOT_PATH=<PATH>] [ROOT_SKEL_PATH=<PATH>] [ROOT_OUT=<PATH>] [ROOT_COMPRESSOR=<COMPRESSOR>] [LINUX_MODULES_INSTALL_PATH=<PATH>]

Arguments:
clean|dist-clean: Clean up working directory and quit (default: Don't quit)
dist-clean-build: Clean up and build (is the default, here for ease of use)
no-nuke: Don't nuke already built objects (default: do nuke them)

ROOT_PATH=<PATH>: PATH to existing set of initrd files (required)
ROOT_SKEL_PATH=<PATH>: PATH to initrd skeleton (required)
LINUX_MODULES_INSTALL_PATH=<PATH>: Path to installed Linux modules (required)
EOF
}

CLEAN_BUILD=1
CREATE_ROOT=1
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
            CREATE_ROOT=1
            DO_WORK=1
            shift
            ;;
        clean|dist-clean)
            CLEAN_BUILD=1
            CREATE_ROOT=0
            DO_WORK=0
            shift
            ;;
        ROOT_PATH=*)
            ROOT_PATH="$(get_var_val "$1")"
            shift
            ;;
        ROOT_SKEL_PATH=*)
            ROOT_SKEL_PATH="$(get_var_val "$1")"
            shift
            ;;
        LINUX_MODULES_INSTALL_PATH=*)
            LINUX_MODULES_INSTALL_PATH="$(get_var_val "$1")"
            shift
            ;;
        help|-h|--help)
            create_initrd_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            create_initrd_help
            exit 1
            ;;
    esac
done

EXIT_HELP=0

if [ -z "${ROOT_PATH}" ]
then
    echo "\$ROOT_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${ROOT_SKEL_PATH}" ]
then
    echo "\$ROOT_SKEL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${LINUX_MODULES_INSTALL_PATH}" ]
then
    echo "\$LINUX_MODULES_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    create_initrd_help
    exit 1
fi

ROOT_MODULES_PATH="${ROOT_PATH}/${MODULES_DIR}"

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    echo "Cleaning root directories..."
    rm -rf "${ROOT_PATH}/*"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi

if [ "${CREATE_ROOT}" -eq 1 ]
then
    echo "Creating root directories..."
    OLD_PWD="${PWD}"
    cd "${ROOT_PATH}"
    cp -a "${ROOT_SKEL_PATH}"/* "${ROOT_PATH}"
    cp -a "${LINUX_MODULES_INSTALL_PATH}"/* "${ROOT_PATH}"
    KERNEL_VER="$(ls "${ROOT_MODULES_PATH}")"
    ROOT_MODULES_VER_PATH="${ROOT_MODULES_PATH}/${KERNEL_VER}"
    cd "${OLD_PWD}"
fi

echo "Done"
