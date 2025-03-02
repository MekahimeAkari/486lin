#!/bin/sh
set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

MODULES_DIR="lib/modules"
GET_MODDEPS_SCRIPT_NAME="get_moddeps.sh"
GET_MODDEPS_SCRIPT="${SCRIPTS_DIR}/get/${GET_MODDEPS_SCRIPT_NAME}"

create_initrd_help()
{
cat << EOF
Initrd create script for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean] | [dist-clean-build] [no-nuke] [INITRD_PATH=<PATH>] [INITRD_SKEL_PATH=<PATH>] [INITRD_OUT=<PATH>] [INITRD_COMPRESSOR=<COMPRESSOR>] [LINUX_MODULES_INSTALL_PATH=<PATH>]

Arguments:
clean|dist-clean: Clean up working directory and quit (default: Don't quit)
dist-clean-build: Clean up and build (is the default, here for ease of use)
no-nuke: Don't nuke already built objects (default: do nuke them)

INITRD_PATH=<PATH>: PATH to existing set of initrd files (required)
INITRD_SKEL_PATH=<PATH>: PATH to initrd skeleton (required)
INITRD_OUT=<PATH>: Output PATH of initrd (required)
INITRD_COMPRESSOR=<COMPRESSOR>: Initrd compressor (required)
LINUX_MODULES_INSTALL_PATH=<PATH>: Path to installed Linux modules (required)
EOF
}

CLEAN_BUILD=1
CREATE_INITRD=1
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
            CREATE_INITRD=1
            DO_WORK=1
            shift
            ;;
        clean|dist-clean)
            CLEAN_BUILD=1
            CREATE_INITRD=0
            DO_WORK=0
            shift
            ;;
        INITRD_PATH=*)
            INITRD_PATH="$(get_var_val "$1")"
            shift
            ;;
        INITRD_SKEL_PATH=*)
            INITRD_SKEL_PATH="$(get_var_val "$1")"
            shift
            ;;
        INITRD_OUT=*)
            INITRD_OUT="$(get_var_val "$1")"
            shift
            ;;
        INITRD_COMPRESSOR=*)
            INITRD_COMPRESSOR="$(get_var_val "$1")"
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

if [ -z "${INITRD_PATH}" ]
then
    echo "\$INITRD_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${INITRD_SKEL_PATH}" ]
then
    echo "\$INITRD_SKEL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${INITRD_OUT}" ]
then
    echo "\$INITRD_OUT is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${INITRD_COMPRESSOR}" ]
then
    echo "\$INITRD_COMPRESSOR is required to be defined"
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

INITRD_MODULES_PATH="${INITRD_PATH}/${MODULES_DIR}"

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    echo "Cleaning initrd and directories..."
    rm -rf "${INITRD_MODULES_PATH}"
    rm -rf "${INITRD_OUT}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi

if [ "${CREATE_INITRD}" -eq 1 ]
then
    MODULE_INFO_FILES="\
        modules.alias \
        modules.builtin \
        modules.builtin.modinfo \
        modules.dep \
        modules.devname \
        modules.order \
        modules.softdep \
        modules.symbols \
    "
    MODULES="\
        font \
        zram \
        loop \
        serdev \
        sd_mod \
        sr_mod \
        sg \
        sparse-keymap \
        matrix-keymap \
        serport \
        cdrom \
        .*pata.* \
        ata_piix \
        ata_generic \
        regmap-i2c \
        rtc-cmos \
        lzo-rle \
        msr \
        cpuid \
        fbdev \
        squashfs \
        overlay \
        isofs \
    "
    echo "Creating initrd..."
    OLD_PWD="${PWD}"
    cd "${INITRD_PATH}"
    cp -a "${INITRD_SKEL_PATH}"/* "${INITRD_PATH}"
    KERNEL_MODULES_ROOT="${LINUX_MODULES_INSTALL_PATH}/${MODULES_DIR}"
    KERNEL_VER="$(ls "${KERNEL_MODULES_ROOT}")"
    KERNEL_MODULES_VER_PATH="${KERNEL_MODULES_ROOT}/${KERNEL_VER}"
    INITRD_MODULES_VER_PATH="${INITRD_MODULES_PATH}/${KERNEL_VER}"
    rm -rf "${INITRD_MODULES_VER_PATH}"
    mkdir -p "${INITRD_MODULES_VER_PATH}"
    for MODULE_INFO_FILE in ${MODULE_INFO_FILES}
    do
        cp "${KERNEL_MODULES_VER_PATH}/${MODULE_INFO_FILE}" "${INITRD_MODULES_VER_PATH}"
    done

    # Not sure the best way to propagate error failure here
    MODULES_NEEDED="$("${GET_MODDEPS_SCRIPT}" "${MODULES}" "LINUX_MODULES_INSTALL_PATH=${LINUX_MODULES_INSTALL_PATH}")"
    for MODULE_NEEDED in ${MODULES_NEEDED}
    do
        mkdir -p "${INITRD_MODULES_VER_PATH}/$(dirname "${MODULE_NEEDED}")"
        cp "${KERNEL_MODULES_VER_PATH}/${MODULE_NEEDED}" "${INITRD_MODULES_VER_PATH}/${MODULE_NEEDED}"
    done

    rm -f "${INITRD_MODULES_VER_PATH}"/modules.alias.new
    rm -f "${INITRD_MODULES_VER_PATH}"/modules.dep.new
    rm -f "${INITRD_MODULES_VER_PATH}"/modules.order.new

    for i in $(grep -v "^#" "${INITRD_MODULES_VER_PATH}/modules.alias" | cut -d ' ' -f 3- | sort | uniq)
    do
        if [ -n "$(find . -name "$i.ko")" ]
        then
            grep " $i" "${INITRD_MODULES_VER_PATH}/modules.alias" >> "${INITRD_MODULES_VER_PATH}/modules.alias.new"
        fi
    done

    mv "${INITRD_MODULES_VER_PATH}/modules.alias.new" "${INITRD_MODULES_VER_PATH}/modules.alias"

    for i in $(cat "${INITRD_MODULES_VER_PATH}/modules.dep" | cut -d ':' -f 1)
    do
        if [ -f "${INITRD_MODULES_VER_PATH}/$i" ]
        then
            grep "$i:" "${INITRD_MODULES_VER_PATH}/modules.dep" >> "${INITRD_MODULES_VER_PATH}/modules.dep.new"
        fi
    done

    mv "${INITRD_MODULES_VER_PATH}/modules.dep.new" "${INITRD_MODULES_VER_PATH}/modules.dep"

    for i in $(cat "${INITRD_MODULES_VER_PATH}/modules.order")
    do
        if [ -f "${INITRD_MODULES_VER_PATH}/$i" ]
        then
            grep "$i" "${INITRD_MODULES_VER_PATH}/modules.order" >> "${INITRD_MODULES_VER_PATH}/modules.order.new"
        fi
    done

    mv "${INITRD_MODULES_VER_PATH}/modules.order.new" "${INITRD_MODULES_VER_PATH}/modules.order"

    find . -print0 | cpio --null --create --verbose --format=newc | ${INITRD_COMPRESSOR} > "${INITRD_OUT}"

    cd "${OLD_PWD}"
fi

echo "Done"
