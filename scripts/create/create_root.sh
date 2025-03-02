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
        loop \
        serdev \
        sr_mod \
        sparse-keymap \
        matrix-keymap \
        serport \
        cdrom \
        .*pata.* \
        ata_piix \
        ata_generic \
        rtc-cmos \
        msr \
        cpuid \
        fbdev \
        squashfs \
        overlay \
        isofs \
        nls.* \
        mac-.* \
        utf8data \
        vfat \
        exfat \
        nfsv.* \
        cifs.* \
        jfs \
        xfs \
        ext4 \
        serport \
        8250.* \
        fdomain_isa \
        pcips2 \
        ps2mult \
        bochs \
        s3fb \
        rivafb \
        matrox.* \
        cirrusfb \
        i740fb \
        i810.* \
        tridentfb \
        uvesafb \
        af_packet.* \
        unix.* \
        ipv6 \
        ac97.* \
        snd-sb.* \
        .*cpufreq.* \
        acpi/.* \
        platform/x86/.* \
        net/ethernet/.* \
    "
    echo "Creating root directories..."
    OLD_PWD="${PWD}"
    cd "${ROOT_PATH}"
    cp -a "${ROOT_SKEL_PATH}"/* "${ROOT_PATH}"
    KERNEL_MODULES_ROOT="${LINUX_MODULES_INSTALL_PATH}/${MODULES_DIR}"
    KERNEL_VER="$(ls "${KERNEL_MODULES_ROOT}")"
    KERNEL_MODULES_VER_PATH="${KERNEL_MODULES_ROOT}/${KERNEL_VER}"
    ROOT_MODULES_VER_PATH="${ROOT_MODULES_PATH}/${KERNEL_VER}"
    rm -rf "${ROOT_MODULES_VER_PATH}"
    mkdir -p "${ROOT_MODULES_VER_PATH}"
    echo "Copying module info files..."
    for MODULE_INFO_FILE in ${MODULE_INFO_FILES}
    do
        cp "${KERNEL_MODULES_VER_PATH}/${MODULE_INFO_FILE}" "${ROOT_MODULES_VER_PATH}"
    done
    echo "done"

    echo "Resolving module dependencies..."
    MODULES_NEEDED="$("${GET_MODDEPS_SCRIPT}" "${MODULES}" "LINUX_MODULES_INSTALL_PATH=${LINUX_MODULES_INSTALL_PATH}")"
    echo "done"
    echo "Copying modules..."
    for MODULE_NEEDED in ${MODULES_NEEDED}
    do
        mkdir -p "${ROOT_MODULES_VER_PATH}/$(dirname "${MODULE_NEEDED}")"
        cp "${KERNEL_MODULES_VER_PATH}/${MODULE_NEEDED}" "${ROOT_MODULES_VER_PATH}/${MODULE_NEEDED}"
    done
    echo "done"

    echo "Trimming module info files..."
    rm -f "${ROOT_MODULES_VER_PATH}"/modules.alias.new
    rm -f "${ROOT_MODULES_VER_PATH}"/modules.dep.new
    rm -f "${ROOT_MODULES_VER_PATH}"/modules.order.new

    for i in $(grep -v "^#" "${ROOT_MODULES_VER_PATH}/modules.alias" | cut -d ' ' -f 3- | sort | uniq)
    do
        if [ -n "$(find . -name "$i.ko")" ]
        then
            grep " $i" "${ROOT_MODULES_VER_PATH}/modules.alias" >> "${ROOT_MODULES_VER_PATH}/modules.alias.new"
        fi
    done

    mv "${ROOT_MODULES_VER_PATH}/modules.alias.new" "${ROOT_MODULES_VER_PATH}/modules.alias"

    for i in $(cat "${ROOT_MODULES_VER_PATH}/modules.dep" | cut -d ':' -f 1)
    do
        if [ -f "${ROOT_MODULES_VER_PATH}/$i" ]
        then
            grep "$i:" "${ROOT_MODULES_VER_PATH}/modules.dep" >> "${ROOT_MODULES_VER_PATH}/modules.dep.new"
        fi
    done

    mv "${ROOT_MODULES_VER_PATH}/modules.dep.new" "${ROOT_MODULES_VER_PATH}/modules.dep"

    for i in $(cat "${ROOT_MODULES_VER_PATH}/modules.order")
    do
        if [ -f "${ROOT_MODULES_VER_PATH}/$i" ]
        then
            grep "$i" "${ROOT_MODULES_VER_PATH}/modules.order" >> "${ROOT_MODULES_VER_PATH}/modules.order.new"
        fi
    done

    mv "${ROOT_MODULES_VER_PATH}/modules.order.new" "${ROOT_MODULES_VER_PATH}/modules.order"
    echo "done"


    cd "${OLD_PWD}"
fi

echo "Done"
