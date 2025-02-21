#!/bin/sh

if [ -z "${MUSL_URL}" ]
then
    echo "\$MUSL_URL not defined"
    exit 1
fi
if [ -z "${MUSL_DIR}" ]
then
    echo "\$MUSL_DIR not defined"
    exit 1
fi
if [ -z "${MUSL_INSTALL_DIR}" ]
then
    echo "\$MUSL_INSTALL_DIR not defined"
    exit 1
fi
if [ -z "${MUSL_TAG}" ]
then
    echo "\$MUSL_TAG not defined"
    exit 1
fi

if [ ! -d "${MUSL_DIR}" ]
then
    git clone "${MUSL_URL}" "${MUSL_DIR}"
fi
OLD_PWD="${PWD}"
cd "${MUSL_DIR}"
git stash
git checkout master
git pull --rebase
git checkout "${MUSL_TAG}"
git stash pop || true
make distclean
rm -rf "${MUSL_INSTALL_DIR}"
mkdir -p "${MUSL_INSTALL_DIR}"
./configure CFLAGS="-m32 -march=i486" LDFLAGS=-m32 --prefix="$(realpath ${MUSL_INSTALL_DIR})"
sed -i 's/x32/i386/' config.mak
sed -i 's/-O2/-Os/' config.mak
NPROC="$(nproc)"
if [ -z "${NPROC}" ]
then
    NPROC=2
fi
make -j${NPROC}
make install
cd "${OLD_PWD}"
