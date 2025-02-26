# This is meant to be sourced, don't run this

REPO_DIR="$(realpath "${SCRIPTS_DIR}"/../)"
BUILD_DIR="${SCRIPTS_DIR}/build"
CONFIG_DIR="${SCRIPTS_DIR}/config"
CREATE_DIR="${SCRIPTS_DIR}/create"
GET_DIR="${SCRIPTS_DIR}/get"

get_var_val()
{
    echo "$1" | cut -d = -f 2-
}

set_kbuild_config_val()
{
    CONFIG_FILE="$1"
    shift
    if [ ! -f "${CONFIG_FILE}" ]
    then
        echo "Config file '${CONFIG_FILE}' doesn't exist"
        return 1
    fi

    CONFIG_NAME="CONFIG_$1"
    shift

    if [ "${CONFIG_NAME}" = "CONFIG_" ]
    then
        echo "You must supply a name"
        return 1
    fi

    CONFIG_VAL="$1"
    shift

    if [ "$#" -gt 0 ]
    then
        echo "Excess positional args: '$@'"
        return 1
    fi

    if [ "${CONFIG_VAL}" != "n" ]
    then
        if grep -q "${CONFIG_NAME}" "${CONFIG_FILE}"
        then
            sed -i "s|# ${CONFIG_NAME} is not set|${CONFIG_NAME}=${CONFIG_VAL}|" "${CONFIG_FILE}"
            sed -i "s|${CONFIG_NAME}=.*|${CONFIG_NAME}=${CONFIG_VAL}|" "${CONFIG_FILE}"
        else
            echo "${CONFIG_NAME}=${CONFIG_VAL}" >> "${CONFIG_FILE}"
        fi
    else
        if grep -q "${CONFIG_NAME}" "${CONFIG_FILE}"
        then
            sed -i "s/${CONFIG_NAME}=.*/# ${CONFIG_NAME} is not set/" "${CONFIG_FILE}"
        else
            echo "# ${CONFIG_NAME} is not set" >> "${CONFIG_FILE}"
        fi
    fi
}
