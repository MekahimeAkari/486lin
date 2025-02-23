#!/bin/sh

PLOP_VER="5.15.0"
PLOP_DIR="plpbt-${PLOP_VER}"
PLOP_ZIP_FILE="${PLOP_DIR}.zip"
PLOP_URL="https://download.plop.at/files/bootmngr/${PLOP_ZIP_FILE}"
PLOP_CFG_DIR="Linux"
PLOP_CFG="./plpcfgbt"
PLOP_IMG="plpbt.img"
PLOP_CFG_PATH="${PLOP_DIR}/${PLOP_CFG_DIR}/${PLOP_CFG}"
PLOP_CFG_ARGS="vm=text stf=off dbt=cdrom cnt=on cntval=15"
PLOP_IMG_PATH="${PLOP_DIR}/${PLOP_IMG}"
PLOP_LB_DIR="plopbt-lb"
PLOP_CFG_BIN="plpbt.bin"
PLOP_CFG_TARGET="${PLOP_LB_DIR}/${PLOP_CFG_BIN}"

if [ ! -f "${PLOP_CFG}" ] || [ ! -f "${PLOP_IMG}" ]
then
    if [ ! -d "${PLOP_DIR}" ]
    then
        if [ ! -f "${PLOP_ZIP_FILE}" ]
        then
            wget "${PLOP_URL}" -O "${PLOP_ZIP_FILE}"
        fi
        unzip "${PLOP_ZIP_FILE}" && rm "${PLOP_ZIP_FILE}"
    fi
    cp "${PLOP_CFG_PATH}" "${PLOP_CFG}"
    cp "${PLOP_IMG_PATH}" "${PLOP_IMG}"
    rm -rf "${PLOP_DIR}"
fi

mkdir -p "${PLOP_LB_DIR}"
if mount | grep -q "$(realpath "${PLOP_LB_DIR}")"
then
    sudo umount "${PLOP_LB_DIR}"
fi
sudo mount "${PLOP_IMG}" "${PLOP_LB_DIR}"
sudo "${PLOP_CFG}" ${PLOP_CFG_ARGS} "${PLOP_CFG_TARGET}"
sudo umount "${PLOP_LB_DIR}" && rmdir "${PLOP_LB_DIR}"

