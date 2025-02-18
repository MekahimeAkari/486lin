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
if [ -z "${MUSL_INSTALL_PATH}" ]
then
    echo "\$MUSL_INSTALL_PATH not defined"
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
rm -rf install
mkdir -p install
./configure CFLAGS="-m32 -march=i486" LDFLAGS=-m32 --prefix="${MUSL_INSTALL_PATH}"
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
