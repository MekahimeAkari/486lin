#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

build_dist_help()
{
cat << EOF
Distro builder for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean|dist-clean-build] | [no-linux] [no-musl] [no-busybox] [no-initrd] [no-root] [no-syslinux] [no-nuke]

Arguments:
help|-h|--help: This.
clean: Clean up working directories and quit (default: Don't quit)
dist-clean: Clean up working directories and downloaded artefacts and quit
dist-clean-build: Clean up working directories and downloaded artefacts and build
no-linux: Don't rebuild the linux kernel (default: do rebuild it)
no-musl: Don't rebuild musl libc (default: do rebuild it)
no-busybox: Don't rebuild busybox (default: do rebuild it)
no-initrd: Don't create initrd (default: do create it)
no-root: Don't create root (default: do create it)
no-squash: Don't create squash files (default: do create it)
no-iso: Don't create iso (default: do create it)
no-syslinux: Don't get syslinux (default: do get it)
no-nuke: Don't nuke the build directory (default: do nuke it)
EOF
}

DIST_REPOS="repos"
DIST_BUILD="build"
DIST_ROOT_DIR="root"
DIST_INITRD_DIR="initrd"
DIST_MODULES_DIR="modules"
DIST_ISO_NAME="486lin.iso"
DIST_SQUASHFS_NAME="root.sfs"
DIST_DISK_DIR="disk"
DIST_ISOLINUX_DIR="isolinux"

DIST_ROOT="$(realpath -m "${DIST_BUILD}/${DIST_ROOT_DIR}")"
DIST_INITRD="$(realpath -m "${DIST_BUILD}/${DIST_INITRD_DIR}")"
DIST_DISK="$(realpath -m "${DIST_BUILD}/${DIST_DISK_DIR}")"
DIST_MODULES="$(realpath -m "${DIST_BUILD}/${DIST_MODULES_DIR}")"
DIST_DISK_ISOLINUX="$(realpath -m "${DIST_DISK}/${DIST_ISOLINUX_DIR}")"
DIST_ISO="$(realpath -m "${DIST_BUILD}/${DIST_ISO_NAME}")"
DIST_SQUASHFS="$(realpath -m "${DIST_DISK}/${DIST_SQUASHFS_NAME}")"

SKEL_DIR="skel"
INITRD_SKEL_DIR="initrd"
ROOT_SKEL_DIR="root"
DISK_SKEL_DIR="disk"
SKEL_PATH="${REPO_DIR}/skel"
INITRD_SKEL_PATH="${SKEL_PATH}/${INITRD_SKEL_DIR}"
ROOT_SKEL_PATH="${SKEL_PATH}/${ROOT_SKEL_DIR}"
DISK_SKEL_PATH="${SKEL_PATH}/${DISK_SKEL_DIR}"

LINUX_DIR="linux"
LINUX_HEADERS_INSTALL_DIR="${LINUX_DIR}/install"
LINUX_PATH="$(realpath -m "${DIST_REPOS}/${LINUX_DIR}")"
LINUX_HEADERS_INSTALL_PATH="$(realpath -m "${DIST_REPOS}/${LINUX_HEADERS_INSTALL_DIR}")"
LINUX_BUILD_SCRIPT_NAME="build_linux.sh"
LINUX_BUILD_SCRIPT="${BUILD_DIR}/${LINUX_BUILD_SCRIPT_NAME}"

MUSL_DIR="musl"
MUSL_INSTALL_DIR="${MUSL_DIR}/install"
MUSL_PATH="$(realpath -m "${DIST_REPOS}/${MUSL_DIR}")"
MUSL_INSTALL_PATH="$(realpath -m "${DIST_REPOS}/${MUSL_INSTALL_DIR}")"
MUSL_BIN="$(realpath -m "${MUSL_INSTALL_PATH}/bin")"
MUSL_BUILD_SCRIPT_NAME="build_musl.sh"
MUSL_BUILD_SCRIPT="${BUILD_DIR}/${MUSL_BUILD_SCRIPT_NAME}"

BUSYBOX_CC_NAME="musl-gcc"
BUSYBOX_CC="${MUSL_BIN}/${BUSYBOX_CC_NAME}"
BUSYBOX_EXE_NAME="busybox"
BUSYBOX_ROOT_DIR="busybox_root"
BUSYBOX_ROOT_PATH="$(realpath -m "${DIST_REPOS}/${BUSYBOX_ROOT_DIR}")"
BUSYBOX_ROOT_EXE="$(realpath -m "${BUSYBOX_ROOT_DIR}/${BUSYBOX_EXE_NAME}")"
BUSYBOX_INITRD_DIR="busybox_initrd"
BUSYBOX_INITRD_PATH="$(realpath -m "${DIST_REPOS}/${BUSYBOX_INITRD_DIR}")"
BUSYBOX_INITRD_EXE="$(realpath -m "${BUSYBOX_INITRD_DIR}/${BUSYBOX_EXE_NAME}")"
BUSYBOX_BUILD_SCRIPT_NAME="build_busybox.sh"
BUSYBOX_BUILD_SCRIPT="${BUILD_DIR}/${BUSYBOX_BUILD_SCRIPT_NAME}"

SYSLINUX_DIR="syslinux"
SYSLINUX_PATH="${REPO_DIR}/${SYSLINUX_DIR}"

INITRD_COMPRESSOR="xz --check=crc32"
INITRD_NAME="initrd.xz"
INITRD_OUT_DIR="isolinux"
INITRD_OUT_PATH="${DIST_DISK}/${INITRD_OUT_DIR}"
INITRD_OUT="${INITRD_OUT_PATH}/${INITRD_NAME}"
INITRD_CREATE_SCRIPT_NAME="create_initrd.sh"
INITRD_CREATE_SCRIPT="${CREATE_DIR}/${INITRD_CREATE_SCRIPT_NAME}"

ROOT_CREATE_SCRIPT_NAME="create_root.sh"
ROOT_CREATE_SCRIPT="${CREATE_DIR}/${ROOT_CREATE_SCRIPT_NAME}"
SQUASH_CREATE_SCRIPT_NAME="create_squash.sh"
SQUASH_CREATE_SCRIPT="${CREATE_DIR}/${SQUASH_CREATE_SCRIPT_NAME}"
ISO_CREATE_SCRIPT_NAME="create_iso.sh"
ISO_CREATE_SCRIPT="${CREATE_DIR}/${ISO_CREATE_SCRIPT_NAME}"

SYSLINUX_GET_SCRIPT_NAME="get_syslinux.sh"
SYSLINUX_GET_SCRIPT="${GET_DIR}/${SYSLINUX_GET_SCRIPT_NAME}"

CLEAN_BUILD=1
CLEAN_REPOS=0
BUILD_DIST=1
BUILD_LINUX=1
BUILD_MUSL=1
BUILD_BUSYBOX=1
CREATE_INITRD=1
CREATE_ROOT=1
CREATE_SQUASH=1
CREATE_ISO=1
GET_SYSLINUX=1
EXTRA_ARGS=""

while [ $# -gt 0 ]
do
    case $1 in
        no-nuke)
            CLEAN_BUILD=0
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        no-linux)
            BUILD_LINUX=0
            shift
            ;;
        no-musl)
            BUILD_MUSL=0
            shift
            ;;
        no-busybox)
            BUILD_BUSYBOX=0
            shift
            ;;
        no-initrd)
            CREATE_INITRD=0
            shift
            ;;
        no-root)
            CREATE_ROOT=0
            shift
            ;;
        no-squash)
            CREATE_SQUASH=0
            shift
            ;;
        no-iso)
            CREATE_ISO=0
            shift
            ;;
        no-syslinux)
            GET_SYSLINUX=0
            shift
            ;;
        clean)
            CLEAN_BUILD=1
            BUILD_DIST=0
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        dist-clean)
            CLEAN_BUILD=1
            CLEAN_REPOS=1
            BUILD_DIST=0
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        dist-clean-build)
            CLEAN_BUILD=1
            CLEAN_REPOS=1
            BUILD_DIST=1
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        help|-h|--help)
            build_dist_help
            exit 0
            ;;
        *)
            echo "Unknown arg \'$1\'"
            build_dist_help
            exit 1
            ;;
    esac
done

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    echo "Cleaning build..."
    rm -rf "${DIST_BUILD}"
fi
if [ "${CLEAN_REPOS}" -eq 1 ]
then
    set -x
    echo "Cleaning repos..."
    rm -rf "${DIST_REPOS}"
    rm -rf "${SYSLINUX_PATH}"
    rm -f "${REPO_DIR}"/syslinux*
fi
if [ "${BUILD_DIST}" -eq 0 ]
then
    echo "Done"
    exit 0
fi
mkdir -p "${DIST_BUILD}"
mkdir -p "${DIST_REPOS}"
mkdir -p "${DIST_ROOT}"
mkdir -p "${DIST_INITRD}"
mkdir -p "${DIST_DISK}"
mkdir -p "${DIST_MODULES}"
mkdir -p "${DIST_DISK_ISOLINUX}"

COMMON_DIRS="bin boot dev etc lib mnt proc root run sbin sys tmp usr var"
ROOT_DIRS="${COMMON_DIRS} home etc/init.d"
INITRD_DIRS="${COMMON_DIRS}"
for dir in ${ROOT_DIRS}
do
    mkdir -p "${DIST_ROOT}/${dir}"
done
for dir in ${INITRD_DIRS}
do
    mkdir -p "${DIST_INITRD}/${dir}"
done

if [ "${BUILD_LINUX}" -eq 1 ]
then
    "${LINUX_BUILD_SCRIPT}" \
        ${EXTRA_ARGS} \
        LINUX_PATH="${LINUX_PATH}" \
        LINUX_INSTALL_PATH="${DIST_DISK_ISOLINUX}" \
        LINUX_MODULES_INSTALL_PATH="${DIST_MODULES}" \
        LINUX_HEADERS_INSTALL_PATH="${LINUX_HEADERS_INSTALL_PATH}" \
        || { echo "Building Linux failed"; exit 1; }
fi

if [ "${BUILD_MUSL}" -eq 1 ]
then
    echo "Building Musl libc..."
    "${MUSL_BUILD_SCRIPT}" \
        ${EXTRA_ARGS} \
        MUSL_PATH="${MUSL_PATH}" \
        MUSL_INSTALL_PATH="${MUSL_INSTALL_PATH}" \
        || { echo "Building Musl failed"; exit 1; }
fi\

if [ "${BUILD_BUSYBOX}" -eq 1 ]
then
    "${BUSYBOX_BUILD_SCRIPT}" \
        ${EXTRA_ARGS} \
        BUSYBOX_PATH="${BUSYBOX_ROOT_PATH}" \
        BUSYBOX_CC="${BUSYBOX_CC}" \
        BUSYBOX_INSTALL_PATH="${DIST_ROOT}" \
        BUSYBOX_CONFIG="root" \
        LINUX_HEADERS_INSTALL_PATH="${LINUX_HEADERS_INSTALL_PATH}" \
        || { echo "Building Busybox for root failed"; exit 1; }

    "${BUSYBOX_BUILD_SCRIPT}" \
        ${EXTRA_ARGS} \
        BUSYBOX_CC="${BUSYBOX_CC}" \
        BUSYBOX_PATH="${BUSYBOX_INITRD_PATH}" \
        BUSYBOX_INSTALL_PATH="${DIST_INITRD}" \
        BUSYBOX_CONFIG="initrd" \
        LINUX_HEADERS_INSTALL_PATH="${LINUX_HEADERS_INSTALL_PATH}" \
        || { echo "Building Busybox for initrd failed"; exit 1; }
fi

if [ "${CREATE_INITRD}" -eq 1 ]
then
    "${INITRD_CREATE_SCRIPT}" \
        ${EXTRA_ARGS} \
        INITRD_SKEL_PATH="${INITRD_SKEL_PATH}" \
        INITRD_PATH="${DIST_INITRD}" \
        INITRD_OUT="${INITRD_OUT}" \
        INITRD_COMPRESSOR="${INITRD_COMPRESSOR}" \
        LINUX_MODULES_INSTALL_PATH="${DIST_MODULES}" \
        || { echo "Creating initrd failed"; exit 1; }
fi

if [ "${CREATE_ROOT}" -eq 1 ]
then
    "${ROOT_CREATE_SCRIPT}" \
        ${EXTRA_ARGS} \
        ROOT_SKEL_PATH="${ROOT_SKEL_PATH}" \
        ROOT_PATH="${DIST_ROOT}" \
        LINUX_MODULES_INSTALL_PATH="${DIST_MODULES}" \
        || { echo "Creating root failed"; exit 1; }
fi

if [ "${CREATE_SQUASH}" -eq 1 ]
then
    "${SQUASH_CREATE_SCRIPT}" \
        ${EXTRA_ARGS} \
        ROOT_PATH="${DIST_ROOT}" \
        SQUASH_ROOT_OUT="${DIST_SQUASHFS}" \
        || { echo "Creating squash failed"; exit 1; }
fi

if [ "${GET_SYSLINUX}" -eq 1 ]
then
    "${SYSLINUX_GET_SCRIPT}" \
        ${EXTRA_ARGS} \
        SYSLINUX_PATH="${SYSLINUX_PATH}" \
        || { echo "Getting Syslinux failed"; exit 1; }
fi

if [ "${CREATE_ISO}" -eq 1 ]
then
    "${ISO_CREATE_SCRIPT}" \
        ${EXTRA_ARGS} \
        DISK_PATH="${DIST_DISK}" \
        DISK_SKEL_PATH="${DISK_SKEL_PATH}" \
        SYSLINUX_PATH="${SYSLINUX_PATH}" \
        ISO_OUT="${DIST_ISO}" \
        || { echo "Creating iso failed"; exit 1; }
fi

echo "Done"
