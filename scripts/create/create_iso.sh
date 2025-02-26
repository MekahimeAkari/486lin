#!/bin/sh
set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

create_iso_help()
{
cat << EOF
Live iso create script for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean] | [dist-clean-build] [no-nuke] [DISK_PATH=<PATH>] [DISK_SKEL_PATH=<PATH>] [SYSLINUX_PATH=<PATH>] [ISO_OUT=<PATH>]

Arguments:
clean|dist-clean: Clean up working directory and quit (default: Don't quit)
dist-clean-build: Clean up and build (is the default, here for ease of use)
no-nuke: Don't nuke already built objects (default: do nuke them)

DISK_PATH=<PATH>: PATH to directory to be turned into iso (required)
DISK_SKEL_PATH=<PATH>: PATH to disk skeleton (required)
SYSLINUX_PATH=<PATH>: PATH to Syslinux binaries (required)
ISO_OUT=<PATH>: PATH to output iso (required)
EOF
}

CLEAN_BUILD=1
CREATE_ISO=1
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
            CREATE_ISO=1
            DO_WORK=1
            shift
            ;;
        clean|dist-clean)
            CLEAN_BUILD=1
            CREATE_ISO=0
            DO_WORK=0
            shift
            ;;
        DISK_PATH=*)
            DISK_PATH="$(get_var_val "$1")"
            shift
            ;;
        DISK_SKEL_PATH=*)
            DISK_SKEL_PATH="$(get_var_val "$1")"
            shift
            ;;
        SYSLINUX_PATH=*)
            SYSLINUX_PATH="$(get_var_val "$1")"
            shift
            ;;
        ISO_OUT=*)
            ISO_OUT="$(get_var_val "$1")"
            shift
            ;;
        help|-h|--help)
            create_iso_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            create_iso_help
            exit 1
            ;;
    esac
done

EXIT_HELP=0

if [ -z "${DISK_PATH}" ]
then
    echo "\$DISK_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${DISK_SKEL_PATH}" ]
then
    echo "\$DISK_SKEL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${SYSLINUX_PATH}" ]
then
    echo "\$SYSLINUX_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${ISO_OUT}" ]
then
    echo "\$ISO_OUT is required to be defined"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    create_iso_help
    exit 1
fi

## FIXME - move kernel/initrd install to another directory so disk/ can be cleaned
if [ "${CLEAN_BUILD}" -eq 1 ]
then
    echo "Cleaning iso..."
    rm -rf "${ISO_OUT}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi

if [ "${CREATE_ISO}" -eq 1 ]
then
    echo "Creating iso..."
    OLD_PWD="${PWD}"
    cd "${DISK_PATH}"
    cp -a "${DISK_SKEL_PATH}"/* "${DISK_PATH}"
    cp "${SYSLINUX_PATH}/bios/core/isolinux.bin" "${DISK_PATH}/isolinux"
    cp "${SYSLINUX_PATH}/bios/com32/elflink/ldlinux/ldlinux.c32" "${DISK_PATH}/isolinux"
    mkisofs -o "${ISO_OUT}" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        "${DISK_PATH}"
    cd "${OLD_PWD}"
fi

echo "Done"
