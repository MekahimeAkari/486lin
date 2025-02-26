#!/bin/sh
set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

MODULES_DIR="lib/modules"

create_squash_help()
{
cat << EOF
Live squashfs create script for 486lin

Useage: $0 [help|-h|--help] | [clean|dist-clean] | [dist-clean-build] [no-nuke] [ROOT_PATH=<PATH>] [SQUASH_ROOT_OUT=<PATH>]

Arguments:
clean|dist-clean: Clean up working directory and quit (default: Don't quit)
dist-clean-build: Clean up and build (is the default, here for ease of use)
no-nuke: Don't nuke already built objects (default: do nuke them)

ROOT_PATH=<PATH>: PATH to existing set of initrd files (required)
SQUASH_ROOT_OUT=<PATH>: PATH to output root squash file (required)
EOF
}

SQUASH_COMPRESSOR="gzip"
SQUASH_EXTRA_ARGS="-noappend -no-recovery -all-root"
CLEAN_BUILD=1
CREATE_SQUASH=1
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
            CREATE_SQUASH=1
            DO_WORK=1
            shift
            ;;
        clean|dist-clean)
            CLEAN_BUILD=1
            CREATE_SQUASH=0
            DO_WORK=0
            shift
            ;;
        ROOT_PATH=*)
            ROOT_PATH="$(get_var_val "$1")"
            shift
            ;;
        SQUASH_ROOT_OUT=*)
            SQUASH_ROOT_OUT="$(get_var_val "$1")"
            shift
            ;;
        help|-h|--help)
            create_squash_help
            exit
            ;;
        *)
            echo "Unknown arg \'$1\'"
            create_squash_help
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

if [ -z "${SQUASH_ROOT_OUT}" ]
then
    echo "\$SQUASH_ROOT_OUT is required to be defined"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    create_squash_help
    exit 1
fi

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    echo "Cleaning squash..."
    rm -rf "${SQUASH_ROOT_OUT}"
fi

if [ "${DO_WORK}" -eq 0 ]
then
    echo "Done"
    exit
fi

if [ "${CREATE_SQUASH}" -eq 1 ]
then
    echo "Creating squash files..."
    OLD_PWD="${PWD}"
    mksquashfs "${ROOT_PATH}" "${SQUASH_ROOT_OUT}" -comp "${SQUASH_COMPRESSOR}" ${SQUASH_EXTRA_ARGS}
    cd "${OLD_PWD}"
fi

echo "Done"
