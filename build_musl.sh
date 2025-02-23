#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPT_DIR}/${COMMON_FUNCS_NAME}"

MUSL_URL="git://git.musl-libc.org/musl"
MUSL_TAG="v1.2.5"
BUILD_JOBS="$(nproc)"
if [ -z "${BUILD_JOBS}" ]
then
    BUILD_JOBS=2
fi

build_musl_help()
{
cat << EOF
Musl libc builder for 486lin
Musl git repo: '${MUSL_URL}'
Musl tag: '${MUSL_TAG}'

Useage: $0 [help|-h|--help] | [clean|dist-clean|dist-clean-build] | [no-nuke] [no-pull] [no-build] [no-install] [-j] [MUSL_PATH=<PATH>] [MUSL_INSTALL_PATH=<PATH>]

Arguments:
clean: Clean up working directory and quit (default: Don't quit)
dist-clean: Clean up working directory and downloaded artefacts and quit
dist-clean-build: Clean up working directory and downloaded artefacts and do something
no-nuke: Don't nuke already built objects (default: do nuke them)
no-pull: Don't try to pull the git repo (default: do pull)
no-build: Don't build anything, just install existing items if no-install isn't used (default: build)
no-install: Don't install anything, just build if no-build isn't used (default: install)
-j: Parallel build jobs (default: '${BUILD_JOBS}')

MUSL_PATH=<PATH>: PATH to the Musl source repo (required)
MUSL_INSTALL_PATH=<PATH>: PATH to where Musl should be installed (required if not no-install)
EOF
}

set -x

PULL_REPO=1
CLEAN_BUILD=1
CLEAN_REPOS=0
BUILD_MUSL=1
INSTALL_MUSL=1
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
            BUILD_MUSL=0
            shift
            ;;
        no-install)
            INSTALL_MUSL=0
            shift
            ;;
        clean)
            CLEAN_BUILD=1
            BUILD_MUSL=0
            PULL_REPO=0
            INSTALL_MUSL=0
            DO_WORK=0
            shift
            ;;
        dist-clean)
            CLEAN_REPOS=1
            CLEAN_BUILD=1
            BUILD_MUSL=0
            PULL_REPO=0
            INSTALL_MUSL=0
            DO_WORK=0
            shift
            ;;
        dist-clean-build)
            CLEAN_REPOS=1
            CLEAN_BUILD=1
            shift
            ;;
        MUSL_PATH=*)
            MUSL_PATH="$(get_var_val "$1")"
            shift
            ;;
        MUSL_INSTALL_PATH=*)
            MUSL_INSTALL_PATH="$(get_var_val "$1")"
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
            build_musl_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            build_musl_help
            exit 1
            ;;
    esac
done

EXIT_HELP=0

CONFIG_PATH="$(realpath -m "${LINUX_PATH}/.config")"

if [ -z "${MUSL_PATH}" ]
then
    echo "\$MUSL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${INSTALL_MUSL}" -eq 1 ] && [ -z "${MUSL_INSTALL_PATH}" ]
then
    echo "Musl install requested: \$MUSL_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    build_musl_help
    exit 1
fi

if [ "${CLEAN_REPOS}" -eq 1 ]
then
    rm -rf "${MUSL_PATH}"
fi

if [ "${PULL_REPO}" -eq 1 ]
then
    if [ ! -d "${MUSL_PATH}" ]
    then
        git clone "${MUSL_URL}" "${MUSL_PATH}"
    fi

    OLD_PWD="${PWD}"
    cd "${MUSL_PATH}"
    git stash
    git checkout master
    git pull --rebase
    git checkout "${MUSL_TAG}"
    git stash pop || true
    cd "${OLD_PWD}"
fi

if [ "${CLEAN_BUILD}" -eq 1 ] && [ "${CLEAN_REPOS}" -eq 0 ]
then
    OLD_PWD="${PWD}"
    cd "${MUSL_PATH}"
    make distclean
    cd "${OLD_PWD}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    exit
fi

if [ "${BUILD_MUSL}" -eq 1 ]
then
    OLD_PWD="${PWD}"
    cd "${MUSL_PATH}"

    ./configure \
        CFLAGS="-m32 -march=i486" \
        LDFLAGS="-m32" \
        --prefix="${MUSL_INSTALL_PATH}"

    sed -i 's/x32/i386/' config.mak
    sed -i 's/-O2/-Os/' config.mak

    make -j"${BUILD_JOBS}"
    cd "${OLD_PWD}"
fi

if [ "${INSTALL_MUSL}" ]
then
    OLD_PWD="${PWD}"
    cd "${MUSL_PATH}"
    rm -rf "${MUSL_INSTALL_PATH}"
    mkdir -p "${MUSL_INSTALL_PATH}"
    make install
    cd "${OLD_PWD}"
fi
