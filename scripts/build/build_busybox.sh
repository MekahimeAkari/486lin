#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

BUSYBOX_URL="git://git.busybox.net/busybox"
BUSYBOX_BRANCH="1_37_stable"
BUSYBOX_CC="gcc"
BUSYBOX_CONFIG_NAME=".config"
BUSYBOX_CFLAGS="-m32 -march=i486 -Wl,-m -Wl,elf_i386 -static -static-libgcc"
BUSYBOX_EXPECTED_CONFIGS="initrd root"
BUSYBOX_PATCHES_DIR="patches/busybox"
BUSYBOX_PATCHES_PATH="${REPO_DIR}/${BUSYBOX_PATCHES_DIR}"
BUILD_JOBS="$(nproc)"
if [ -z "${BUILD_JOBS}" ]
then
    BUILD_JOBS=2
fi

build_busybox_help()
{
cat << EOF
Busybox builder for 486lin
Busybox git repo: '${BUSYBOX_URL}'
Busybox branch: '${BUSYBOX_BRANCH}'

Useage: $0 [help|-h|--help] | [clean|dist-clean|dist-clean-build] | [no-nuke] [no-pull] [no-build] [no-install] [-j] [BUSYBOX_PATH=<PATH>] [BUSYBOX_INSTALL_PATH=<PATH>] [BUSYBOX_CC=<PATH>] [BUSYBOX_CONFIG=<CONFIG>] [LINUX_HEADERS_INSTALL_PATH=<PATH>]

Arguments:
clean: Clean up working directory and quit (default: Don't quit)
dist-clean: Clean up working directory and downloaded artefacts and quit
dist-clean-build: Clean up working directory and downloaded artefacts and do something
no-nuke: Don't nuke already built objects (default: do nuke them)
no-pull: Don't try to pull the git repo (default: do pull)
no-build: Don't build anything, just install existing items if no-install isn't used (default: build)
no-install: Don't install anything, just build if no-build isn't used (default: install)
-j: Parallel build jobs (default: '${BUILD_JOBS}')

BUSYBOX_PATH=<PATH>: PATH to the Busybox source repo (required)
BUSYBOX_CC=<PATH>: PATH to complier to use for Busybox (default '${BUSYBOX_CC}')
BUSYBOX_CONFIG=<CONFIG>: CONFIG to build Busybox, will call busybox_CONFIG_config.sh (required if not no-build, configs expected to exist are '${BUSYBOX_EXPECTED_CONFIGS}')
BUSYBOX_INSTALL_PATH=<PATH>: PATH to where the Busybox executable should be installed (required if not no-install)
EOF
}

BUSYBOX_CONFIG=
PULL_REPO=1
CLEAN_BUILD=1
CLEAN_REPOS=0
BUILD_BUSYBOX=1
INSTALL_BUSYBOX=1
DO_WORK=1

while [ $# -gt 0 ]
do
    case $1 in
        no-nuke)
            CLEAN_BUILD=0
            shift
            ;;
        no-pull)
            PULL_REPO=0
            shift
            ;;
        no-build)
            BUILD_BUSYBOX=0
            shift
            ;;
        no-install)
            INSTALL_BUSYBOX=0
            shift
            ;;
        clean)
            CLEAN_BUILD=1
            BUILD_BUSYBOX=0
            PULL_REPO=0
            INSTALL_BUSYBOX=0
            DO_WORK=0
            shift
            ;;
        dist-clean)
            CLEAN_REPOS=1
            CLEAN_BUILD=1
            BUILD_BUSYBOX=0
            PULL_REPO=0
            INSTALL_BUSYBOX=0
            DO_WORK=0
            shift
            ;;
        dist-clean-build)
            CLEAN_REPOS=1
            CLEAN_BUILD=1
            shift
            ;;
        BUSYBOX_PATH=*)
            BUSYBOX_PATH="$(get_var_val "$1")"
            shift
            ;;
        BUSYBOX_INSTALL_PATH=*)
            BUSYBOX_INSTALL_PATH="$(get_var_val "$1")"
            shift
            ;;
        BUSYBOX_CC=*)
            BUSYBOX_CC="$(get_var_val "$1")"
            shift
            ;;
        BUSYBOX_CONFIG=*)
            BUSYBOX_CONFIG="$(get_var_val "$1")"
            BUSYBOX_CONFIG_SCRIPT="${CONFIG_DIR}/config_busybox_${BUSYBOX_CONFIG}.sh"
            shift
            ;;
        LINUX_HEADERS_INSTALL_PATH=*)
            LINUX_HEADERS_INSTALL_PATH="$(get_var_val "$1")"
            shift
            ;;
        -j*)
            if [ "$1" = "-j" ]
            then
                shift
                BUILD_JOBS="$1"
            else
                BUILD_JOBS="$(echo -- "$1" | tail -n +3)"
            fi
            shift
            if ! expr "${BUILD_JOBS}" '*' '1' > /dev/null
            then
                echo "Invalid number of jobs \'${BUILD_JOBS}\'"
                build_linux_help
                exit
            fi
            ;;
        help|-h|--help)
            build_busybox_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            build_busybox_help
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

if [ "${INSTALL_BUSYBOX}" -eq 1 ] && [ -z "${BUSYBOX_INSTALL_PATH}" ]
then
    echo "Busybox install requested: \$BUSYBOX_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${BUILD_BUSYBOX}" -eq 1 ]
then
    if [ -z "${BUSYBOX_CONFIG}" ]
    then
        echo "Busybox build requested: \$BUSYBOX_CONFIG is required to be defined"
        EXIT_HELP=1
    fi
    if [ -z "${LINUX_HEADERS_INSTALL_PATH}" ]
    then
        echo "Busybox build requested: \$LINUX_HEADERS_INSTALL_PATH is required to be defined"
        EXIT_HELP=1
    fi
    if [ -z "${BUSYBOX_CONFIG}" ]
    then
        echo "Busybox build requested: \$BUSYBOX_CONFIG is required to be defined"
        EXIT_HELP=1
    fi
fi

if [ -n "${BUSYBOX_CONFIG}" ] && [ ! -f "${BUSYBOX_CONFIG_SCRIPT}" ]
then
    echo "Config script \'${BUSYBOX_CONFIG_SCRIPT}\' for \$BUSYBOX_CONFIG=${BUSYBOX_CONFIG} cannot be found"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    build_busybox_help
    exit 1
fi

BUSYBOX_CONFIG_PATH="${BUSYBOX_PATH}/${BUSYBOX_CONFIG_NAME}"
BUSYBOX_CFLAGS="${BUSYBOX_CFLAGS} -I${LINUX_HEADERS_INSTALL_PATH}/include"
BUSYBOX_CC_LINE="${BUSYBOX_CC} ${BUSYBOX_CFLAGS}"

if [ "${CLEAN_REPOS}" -eq 1 ]
then
    echo "Cleaning Busybox repo..."
    rm -rf "${BUSYBOX_PATH}"
fi

if [ "${PULL_REPO}" -eq 1 ]
then
    if [ ! -d "${BUSYBOX_PATH}" ]
    then
        echo "Busybox repo doesn't exist, cloning..."
        git clone "${BUSYBOX_URL}" "${BUSYBOX_PATH}"
    fi

    echo "Updating Busybox repo..."
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    git stash
    git checkout "${BUSYBOX_BRANCH}"
    git pull --rebase
    git stash pop || true
    sed -i 's/^main()/int main()/' "${BUSYBOX_PATH}/scripts/kconfig/lxdialog/check-lxdialog.sh"
    if ! grep -q "#ifndef TCA_CBQ_MAX" "${BUSYBOX_PATH}/networking/tc.c"
    then
        git apply "${BUSYBOX_PATCHES_PATH}/tca_cbq_removed.patch"
    fi
    cd "${OLD_PWD}"
fi

if [ "${CLEAN_BUILD}" -eq 1 ] && [ "${CLEAN_REPOS}" -eq 0 ]
then
    echo "Cleaning Busybox build..."
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    rm -f "${BUSYBOX_CONFIG_PATH}"
    make mrproper
    cd "${OLD_PWD}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi


if [ "${BUILD_BUSYBOX}" -eq 1 ]
then
    echo "Configuring Busybox..."
    "${BUSYBOX_CONFIG_SCRIPT}" \
        BUSYBOX_PATH="${BUSYBOX_PATH}" \
        BUSYBOX_CC_LINE="${BUSYBOX_CC_LINE}"
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    echo "Building Busybox..."
    make -j"${BUILD_JOBS}" \
        HOSTCC="${BUSYBOX_CC_LINE}" \
        CC="${BUSYBOX_CC_LINE}"
    cd "${OLD_PWD}"
fi

if [ "${INSTALL_BUSYBOX}" -eq 1 ]
then
    echo "Installing Busybox..."
    OLD_PWD="${PWD}"
    cd "${BUSYBOX_PATH}"
    make install -j"${BUILD_JOBS}" \
        HOSTCC="${BUSYBOX_CC_LINE}" \
        CC="${BUSYBOX_CC_LINE}" \
        CONFIG_PREFIX="${BUSYBOX_INSTALL_PATH}"
    cd "${OLD_PWD}"
fi

echo "Done"

