#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

LINUX_URL="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
LINUX_BRANCH="linux-6.1.y"
BUILD_JOBS="$(nproc)"
if [ -z "${BUILD_JOBS}" ]
then
    BUILD_JOBS=2
fi

build_linux_help()
{
cat << EOF
Linux kernel builder for 486lin
Linux git repo: '${LINUX_URL}'
Linux branch: '${LINUX_BRANCH}'

Useage: $0 [help|-h|--help] | [clean|dist-clean|dist-clean-build] | [no-nuke] [no-pull] [no-build] [no-install] [no-install-{kernel,modules,headers}] [-j] [LINUX_PATH=<PATH>] [LINUX_INSTALL_PATH=<PATH>] [LINUX_MODULES_INSTALL_PATH=<PATH>] [LINUX_HEADERS_INSTALL_PATH=<PATH>] [CONFIG=<PATH>]

Arguments:
clean: Clean up working directory and quit (default: Don't quit)
dist-clean: Clean up working directory and downloaded artefacts and quit
dist-clean-build: Clean up working directory and downloaded artefacts and do something
no-nuke: Don't nuke already built objects (default: do nuke them)
no-pull: Don't try to pull the git repo (default: do pull)
no-build: Don't build anything, just install existing items if no-install isn't used (default: build, implies no-nuke)
no-install-kernel: Don't install the kernel (default: install)
no-install-modules: Don't install modules (default: install)
no-install-headers: Don't install headers (default: install)
no-install: Don't install anything (=no-install-*), just build if no-build isn't used (default: install)
-j: Parallel build jobs (default: '${BUILD_JOBS}')

CONFIG=<PATH>: PATH to kernel config file
LINUX_PATH=<PATH>: PATH to the Linux source repo (required)
LINUX_INSTALL_PATH=<PATH>: PATH to where the kernel should be installed (required if not no-install-kernel)
LINUX_MODULES_INSTALL_PATH=<PATH>: PATH to where the modules should be installed (required if not no-install-modules)
LINUX_HEADERS_INSTALL_PATH=<PATH>: PATH to where the headers should be installed (required if not no-install-headers)
EOF
}

PULL_REPO=1
CLEAN_BUILD=1
CLEAN_REPOS=0
BUILD_LINUX=1
INSTALL_KERNEL=1
INSTALL_HEADERS=1
INSTALL_MODULES=1
DO_WORK=1
EXTRA_ARGS=""

while [ $# -gt 0 ]
do
    case $1 in
        no-nuke)
            CLEAN_BUILD=0
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        no-pull)
            PULL_REPO=0
            shift
            ;;
        no-build)
            BUILD_LINUX=0
            CLEAN_BUILD=0
            EXTRA_ARGS="${EXTRA_ARGS} no-nuke"
            shift
            ;;
        no-install-kernel)
            INSTALL_KERNEL=0
            shift
            ;;
        no-install-modules)
            INSTALL_MODULES=0
            shift
            ;;
        no-install-headers)
            INSTALL_HEADERS=0
            shift
            ;;
        no-install)
            INSTALL_KERNEL=0
            INSTALL_MODULES=0
            INSTALL_HEADERS=0
            shift
            ;;
        clean)
            CLEAN_BUILD=1
            BUILD_LINUX=0
            PULL_REPO=0
            INSTALL_KERNEL=0
            INSTALL_MODULES=0
            INSTALL_HEADERS=0
            DO_WORK=0
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        dist-clean)
            CLEAN_REPOS=1
            CLEAN_BUILD=1
            BUILD_LINUX=0
            PULL_REPO=0
            INSTALL_KERNEL=0
            INSTALL_MODULES=0
            INSTALL_HEADERS=0
            DO_WORK=0
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        dist-clean-build)
            CLEAN_REPOS=1
            CLEAN_BUILD=1
            EXTRA_ARGS="${EXTRA_ARGS} $1"
            shift
            ;;
        CONFIG=*)
            CONFIG="$(get_var_val "$1")"
            shift
            ;;
        LINUX_PATH=*)
            LINUX_PATH="$(get_var_val "$1")"
            shift
            ;;
        LINUX_INSTALL_PATH=*)
            LINUX_INSTALL_PATH="$(get_var_val "$1")"
            shift
            ;;
        LINUX_HEADERS_INSTALL_PATH=*)
            LINUX_HEADERS_INSTALL_PATH="$(get_var_val "$1")"
            shift
            ;;
        LINUX_MODULES_INSTALL_PATH=*)
            LINUX_MODULES_INSTALL_PATH="$(get_var_val "$1")"
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
            build_linux_help
            exit
            ;;
        *)
            echo "Unknown arg '$1'"
            build_linux_help
            exit 1
            ;;
    esac
done

EXIT_HELP=0

LINUX_CONFIG_PATH="$(realpath -m "${LINUX_PATH}/.config")"

if [ -z "${LINUX_PATH}" ]
then
    echo "\$LINUX_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ -z "${CONFIG}" ]
then
    echo "\$CONFIG is required to be defined"
    EXIT_HELP=1
fi

if [ "${INSTALL_KERNEL}" -eq 1 ] && [ -z "${LINUX_INSTALL_PATH}" ]
then
    echo "Kernel install requested: \$LINUX_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${INSTALL_HEADERS}" -eq 1 ] && [ -z "${LINUX_HEADERS_INSTALL_PATH}" ]
then
    echo "Header install requested: \$LINUX_HEADERS_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${INSTALL_MODULES}" -eq 1 ] && [ -z "${LINUX_MODULES_INSTALL_PATH}" ]
then
    echo "Module install requested: \$LINUX_MODULES_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    build_linux_help
    exit 1
fi

if [ "${CLEAN_REPOS}" -eq 1 ]
then
    echo "Cleaning Linux repo..."
    rm -rf "${LINUX_PATH}"
fi

if [ "${PULL_REPO}" -eq 1 ]
then
    if [ ! -d "${LINUX_PATH}" ]
    then
        echo "Repo doesn't exist, cloning..."
        git clone "${LINUX_URL}" "${LINUX_PATH}"
    fi

    OLD_PWD="${PWD}"
    cd "${LINUX_PATH}"
    echo "Updating Linux repo..."
    git stash
    git checkout "${LINUX_BRANCH}"
    git pull --rebase
    git stash pop || true
    cd "${OLD_PWD}"
fi

if [ "${CLEAN_BUILD}" -eq 1 ] && [ "${CLEAN_REPOS}" -eq 0 ]
then
    echo "Cleaning Linux build..."
    OLD_PWD="${PWD}"
    cd "${LINUX_PATH}"
    rm -f "${LINUX_CONFIG_PATH}"
    make mrproper
    cd "${OLD_PWD}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi

if [ "${BUILD_LINUX}" -eq 1 ]
then
    OLD_PWD="${PWD}"
    cd "${LINUX_PATH}"
    echo "Configuring Linux..."
    cp "${CONFIG}" "${LINUX_CONFIG_PATH}"
    make olddefconfig
    echo "Building Linux..."
    make -j"${BUILD_JOBS}"
    cd "${OLD_PWD}"
fi

if [ "${INSTALL_HEADERS}" -eq 1 ]
then
    echo "Installing Linux kernel headers..."
    OLD_PWD="${PWD}"
    cd "${LINUX_PATH}"
    rm -rf "${LINUX_HEADERS_INSTALL_PATH}"
    mkdir -p "${LINUX_HEADERS_INSTALL_PATH}"
    make headers_install INSTALL_HDR_PATH="${LINUX_HEADERS_INSTALL_PATH}"
    cd "${OLD_PWD}"
fi

if [ "${INSTALL_MODULES}" -eq 1 ]
then
    echo "Installing Linux kernel modules..."
    OLD_PWD="${PWD}"
    cd "${LINUX_PATH}"
    rm -rf "${LINUX_MODULES_INSTALL_PATH}"
    mkdir -p "${LINUX_MODULES_INSTALL_PATH}"
    make modules_install INSTALL_MOD_PATH="${LINUX_MODULES_INSTALL_PATH}"
    cd "${OLD_PWD}"
fi

if [ "${INSTALL_KERNEL}" -eq 1 ]
then
    echo "Installing Linux kernel..."
    OLD_PWD="${PWD}"
    cd "${LINUX_PATH}"
    rm -rf "${LINUX_INSTALL_PATH}"/*vmlinuz*
    rm -rf "${LINUX_INSTALL_PATH}"/*System.map*
    rm -rf "${LINUX_INSTALL_PATH}"/*config-*
    make install INSTALL_PATH="${LINUX_INSTALL_PATH}"
    cd "${LINUX_INSTALL_PATH}"
    mv vmlinuz* vmlinuz
    cd "${OLD_PWD}"
fi
echo "Done"
