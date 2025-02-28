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
    echo "Creating initrd..."
    OLD_PWD="${PWD}"
    cd "${INITRD_PATH}"
    cp -a "${INITRD_SKEL_PATH}"/* "${INITRD_PATH}"
    cp -a "${LINUX_MODULES_INSTALL_PATH}"/* "${INITRD_PATH}"
    KERNEL_VER="$(ls "${INITRD_MODULES_PATH}")"
    INITRD_MODULES_VER_PATH="${INITRD_MODULES_PATH}/${KERNEL_VER}"
    rm -rf "${INITRD_MODULES_VER_PATH}"/*.bin
    rm -rf "${INITRD_MODULES_VER_PATH}"/modules.symbols
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/net
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/sound
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/nfs*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/ntfs*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/exfat
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/smb*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/lockd
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/fuse
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/autofs
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/binfmt_misc*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/hfsplus
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/jbd2
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/ext*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/udf
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/nls
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/fs/pstore
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/gpu
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/net
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/platform
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/hwmon
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/media
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*isc*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*raid*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/pcmcia
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*sas*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*3w*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*qla*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*NCR*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*esp*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*nsp*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/*aha*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/ips*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/ppa*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/imm*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/myr*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/stex*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/initio*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/hptiop*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/atp*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/wd*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/dmx*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/fdomain*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/qlogic*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/a100*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/am53*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/snic
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/hpsa*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/sym53c8xx_2
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/esas2r
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/BusLogic*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/advansys*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/mvsas
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/arcmsr
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/be2iscsi
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/smartpqi
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/aacraid
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/ipr*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/aic94xx
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/mpi3mr
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/pm8001
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/megaraid
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/mpt3sas
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/scsi/aic7xxx
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/ata/*ahci*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/ata/*sata*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/mouse*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/rmi4
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/joydev*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/evdev*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/input-leds*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/misc
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/gameport
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/input/ff-memless*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/block/pktcdvd*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/video
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/i2c
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/leds
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/crypto
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/pinctrl
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/mfd
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/firewire
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/char
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/acpi/dptf
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/acpi/button*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/acpi/battery*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/acpi/acpi_pad*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/acpi/sbs*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/acpi/video*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/hid
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/pcmcia
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/block/nbd*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/parport
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/ssb
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/spmi
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/pps
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/connector
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/gpio
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/misc
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/uio
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/power
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/ptp
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/phy
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/bus
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/usb
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/drivers/tty/serial
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/block
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/lib/lz4
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/lib/crypto
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*blake2b*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*sha1*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*sha256*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*sha512*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*ecc*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*gcm*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*cipher*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*hash*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*essiv*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*aes*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*simd*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*rsa*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*af_alg*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*jitter*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*drbg*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*ccm*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*algif*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*xts*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*_generic*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*md*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*gf128*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*echainiv*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*cmac*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*cbc*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*authen*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*arc4*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*aead*
    rm -rf "${INITRD_MODULES_VER_PATH}"/kernel/crypto/*ecb*
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
