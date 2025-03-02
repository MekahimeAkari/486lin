#!/bin/sh

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPTS_DIR="$(realpath "${SCRIPT_DIR}"/../)"
COMMON_FUNCS_NAME="common_funcs.sh"

. "${SCRIPTS_DIR}/${COMMON_FUNCS_NAME}"

get_moddeps_help()
{
cat << EOF

Module dependancy finder for 486lin

Useage: $0 [help|-h|--help] | {MODULE_NAMES...} [LINUX_MODULES_INSTALL_PATH=<PATH>]

Arguments:
{MODULE_NAMES...}: List of module names to find (at least one)

LINUX_MODULES_INSTALL_PATH=<PATH>: Path to where kernel modules are installe (required)
EOF
}

FIND_MODULES=""

while [ $# -gt 0 ]
do
    case $1 in
        LINUX_MODULES_INSTALL_PATH=*)
            LINUX_MODULES_INSTALL_PATH="$(get_var_val "$1")"
            shift
            ;;
        help|-h|--help)
            get_moddeps_help
            exit
            ;;
        *)
            FIND_MODULES="${FIND_MODULES} "$1""
            shift
            ;;
    esac
done

EXIT_HELP=0

if [ -z "${LINUX_MODULES_INSTALL_PATH}" ]
then
    echo "\$LINUX_MODULES_INSTALL_PATH is required to be defined"
    EXIT_HELP=1
fi


if [ -z "${FIND_MODULES}" ]
then
    echo "At least one module must be specified"
    EXIT_HELP=1
fi

if [ "${EXIT_HELP}" -eq 1 ]
then
    get_moddeps_help
    exit 1
fi

MODULES_INSTALL_SUBDIR="lib/modules"
MODULES_INSTALL_ROOT="${LINUX_MODULES_INSTALL_PATH}/${MODULES_INSTALL_SUBDIR}"
KERNEL_VER="$(ls "${MODULES_INSTALL_ROOT}")"
MODULES_DIR="${MODULES_INSTALL_ROOT}/${KERNEL_VER}"
MODULES_DEP_FILE="modules.dep"
MODULES_BUILTIN_FILE="modules.builtin"
MODULES_DEP="${MODULES_DIR}/${MODULES_DEP_FILE}"
MODULES_BUILTIN="${MODULES_DIR}/${MODULES_BUILTIN_FILE}"

FOUND_DEPS=""

get_deps()
{
    FIND_MOD="$1"
    if ! echo "${FIND_MOD}" | grep -q ".ko"
    then
        FIND_MOD="/${FIND_MOD}.ko"
    fi
    echo -n "Looking for ${FIND_MOD}..." 1>&2
    MODDEP_LINES="$(grep "${FIND_MOD}:" "${MODULES_DEP}" || true)"
    if [ -z "${MODDEP_LINES}" ]
    then
        if ! grep -q "${FIND_MOD}" "${MODULES_BUILTIN}"
        then
            echo " no modules found with pattern '${FIND_MOD}'" 1>&2
            exit 1
        else
            echo " found built-in" 1>&2
            return
        fi
    fi
    echo " found" 1>&2
    for MODDEP_LINE in ${MODDEP_LINES}
    do
        MOD="$(echo "${MODDEP_LINE}" | cut -d ':' -f 1)"
        DIRECT_DEPS="$(echo "${MODDEP_LINE}" | cut -d ':' -f 2)"
        if ! echo "${FOUND_DEPS}" | grep -q "${MOD}"
        then
            if [ -z "${FOUND_DEPS}" ]
            then
                FOUND_DEPS="${MOD}"
            else
                FOUND_DEPS="${FOUND_DEPS} ${MOD}"
            fi
        fi
        for NEW_DEP in ${DIRECT_DEPS}
        do
            if ! echo "${FOUND_DEPS}" | grep -q "${NEW_DEP}"
            then
                get_deps "${NEW_DEP}"
            fi
        done
    done
}

for FIND_MODULE in ${FIND_MODULES}
do
    get_deps "${FIND_MODULE}"
done

echo "${FOUND_DEPS}"
