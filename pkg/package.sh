#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${NAME:="graphite-metrictank"}
: ${BUILD_ROOT:="${DIR}/build"}
VERSION="$(git describe --long --always)"
ARCH="$(uname -m)"

# wheezy, other sysvinit
BUILD="${BUILD_ROOT}/sysvinit"
PACKAGE_NAME="${BUILD}/${NAME}-${VERSION}_${ARCH}.deb"
mkdir -p ${BUILD}/etc
cp -a ${BUILD_ROOT}/common/* ${BUILD}/etc/
cp -a ${DIR}/config/sysvinit/init.d ${BUILD}/etc/
cp -r ${BUILD_ROOT}/usr ${BUILD}

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --deb-init ${DIR}/config/sysvinit/init.d/graphite-metrictank \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  -d libcairo2 \
  -d "libffi5 | libffi6" \
  --after-install ${DIR}/debian/post-install \
  --before-remove ${DIR}/debian/pre-remove \
  --after-remove ${DIR}/debian/post-remove \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# ubuntu 14.04

BUILD="${BUILD_ROOT}/upstart"
PACKAGE_NAME="${BUILD}/${NAME}-${VERSION}_${ARCH}.deb"
mkdir -p ${BUILD}
mkdir -p ${BUILD}/etc/init
mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite
cp -a ${BUILD_ROOT}/common/* ${BUILD}/etc/
cp -r ${BUILD_ROOT}/usr ${BUILD}

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --deb-upstart ${DIR}/config/upstart/graphite-metrictank.conf \
  --after-install ${DIR}/general/post-install.sh \
  -d libcairo2 \
  -d "libffi5 | libffi6" \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# ubuntu 16.04, debian jessie

BUILD="${BUILD_ROOT}/systemd"
PACKAGE_NAME="${BUILD}/${NAME}-${VERSION}_${ARCH}.deb"
mkdir -p ${BUILD}
mkdir -p ${BUILD}/lib/systemd/system
mkdir -p ${BUILD}/etc
mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite
cp -a ${BUILD_ROOT}/common/* ${BUILD}/etc/
cp ${DIR}/config/systemd/graphite-metrictank.service ${BUILD}/lib/systemd/system
cp -r ${BUILD_ROOT}/usr ${BUILD}

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --after-install ${DIR}/general/post-install.sh \
  -d libcairo2 \
  -d "libffi5 | libffi6" \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# centos 6

BUILD="${BUILD_ROOT}/upstart-0.6.5"
PACKAGE_NAME="${BUILD}/${NAME}-${VERSION}.el6.${ARCH}.rpm"
mkdir -p ${BUILD}
mkdir -p ${BUILD}/etc/init
mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite
cp -a ${BUILD_ROOT}/common/* ${BUILD}/etc/
cp ${DIR}/config/upstart-0.6.5/graphite-metrictank.conf ${BUILD}/etc/init
cp -r ${BUILD_ROOT}/usr ${BUILD}

fpm \
  -t rpm -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --deb-upstart ${BUILD}/etc/init/graphite-metrictank.conf \
  --after-install ${DIR}/general/post-install-centos.sh \
  -d cairo \
  -d libffi \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# centos 7

BUILD="${BUILD_ROOT}/systemd-centos7"
PACKAGE_NAME="${BUILD}/${NAME}-${VERSION}.el7.${ARCH}.rpm"
mkdir -p ${BUILD}
mkdir -p ${BUILD}/lib/systemd/system
mkdir -p ${BUILD}/etc
mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite
cp -a ${BUILD_ROOT}/common/* ${BUILD}/etc/
cp ${DIR}/config/systemd/graphite-metrictank.service ${BUILD}/lib/systemd/system
cp -r ${BUILD_ROOT}/usr ${BUILD}

fpm \
  -t rpm -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --after-install ${DIR}/general/post-install-centos.sh \
  -d cairo \
  -d libffi \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .
