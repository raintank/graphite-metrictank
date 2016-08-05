#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${NAME:="graphite-metrictank"}
VERSION="$(git describe --long --always)"
ARCH="$(uname -m)"

## copy common files into rootfs/etc for each distro:version
for for target in debian:wheezy; # debian:jessie ubuntu:trusty ubuntu:xenial centos:6 centos7; do
  _distro=${target%:*}
  _version=${target#*:}
  mkdir -p $DIR/$_distro/$_version/etc/
  cp -a $DIR/common/* $DIR/build/$_distro/$_version/etc/
done

# wheezy, other sysvinit
BUILD_ROOT=${DIR}/build
BUILD="${BUILD_ROOT}/debian/wheezy"
PKG_DIR="${DIR}/build/pkg/debian/wheezy"
mkdir -p $PKG_DIR
PACKAGE_NAME="${PKG_DIR}/${NAME}-${VERSION}_${ARCH}.deb"

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --deb-init ${BUILD}/etc/init.d/graphite-metrictank \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  -d libcairo2 \
  -d python \
  -d "libffi5 | libffi6" \
  --after-install ${BUILD_ROOT}/debian/scripts/post-install \
  --before-remove ${BUILD_ROOT}/debian/scripts/pre-remove \
  --after-remove ${BUILD_ROOT}/debian/scripts/post-remove \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# ubuntu 14.04

BUILD="${BUILD_ROOT}/ubuntu/trusty"
PKG_DIR="${DIR}/build/pkg/ubuntu/trusty"
mkdir -p $PKG_DIR
PACKAGE_NAME="${PKG_DIR}/${NAME}-${VERSION}_${ARCH}.deb"


mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --deb-upstart ${BUILD}/etc/init/graphite-metrictank.conf \
  --after-install ${BUILD_ROOT}/ubuntu/scripts/post-install.sh \
  -d libcairo2 \
  -d python \
  -d "libffi5 | libffi6" \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# ubuntu 16.04

BUILD="${BUILD_ROOT}/ubuntu/xenial"
PKG_DIR="${DIR}/build/pkg/ubuntu/xenial"
mkdir -p $PKG_DIR
PACKAGE_NAME="${PKG_DIR}/${NAME}-${VERSION}_${ARCH}.deb"

mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --after-install ${BUILD_ROOT}/ubuntu/scripts/post-install.sh \
  -d libcairo2 \
  -d python \
  -d "libffi5 | libffi6" \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# debian jessie

BUILD="${BUILD_ROOT}/debian/jessie"
PKG_DIR="${DIR}/build/pkg/debian/jessie"
mkdir -p $PKG_DIR
PACKAGE_NAME="${PKG_DIR}/${NAME}-${VERSION}_${ARCH}.deb"

mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite

fpm \
  -t deb -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --after-install ${BUILD_ROOT}/ubuntu/scripts/post-install.sh \
  -d libcairo2 \
  -d python \
  -d "libffi5 | libffi6" \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# centos 6

BUILD="${BUILD_ROOT}/centos/6"
PKG_DIR="${DIR}/build/pkg/centos/6"
mkdir -p $PKG_DIR
PACKAGE_NAME="${PKG_DIR}/${NAME}-${VERSION}.el6.${ARCH}.rpm"

mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite

fpm \
  -t rpm -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --deb-upstart ${BUILD}/etc/init/graphite-metrictank.conf \
  --after-install ${BUILD_ROOT}/centos/scripts/post-install.sh \
  -d cairo \
  -d libffi \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .

# centos 7

BUILD="${BUILD_ROOT}/centos/7"
PKG_DIR="${DIR}/build/pkg/centos/7"
mkdir -p $PKG_DIR
PACKAGE_NAME="${PKG_DIR}/${NAME}-${VERSION}.el7.${ARCH}.rpm"
mkdir -p ${BUILD}/var/lib/graphite
mkdir -p ${BUILD}/var/log/graphite

fpm \
  -t rpm -s dir -C ${BUILD} -n ${NAME} -v $VERSION \
  --config-files /etc/graphite-metrictank/ \
  --config-files /etc/default/graphite-metrictank \
  --after-install ${BUILD_ROOT}/centos/scripts/post-install.sh \
  -d cairo \
  -d libffi \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'finder plugin to use metrictank with graphite-api' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} .
