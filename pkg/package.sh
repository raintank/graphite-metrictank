#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${NAME:="graphite-raintank"}
: ${BUILD_DIR:="${DIR}/build"}
VERSION="1.0.1"
ARCH="$(uname -m)"
PACKAGE_NAME="${DIR}/artifacts/NAME-VERSION-ITERATION_ARCH.deb"
ITERATION=`date +%s`
TAG="pkg-${VERSION}-${ITERATION}"

git tag $TAG

fpm \
  -t deb -s dir -C ${BUILD_DIR} -n ${NAME} -v $VERSION \
  --iteration ${ITERATION} \
  --deb-default ${DIR}/config/ubuntu/trusty/etc/default/graphite-raintank \
  --deb-init ${DIR}/config/ubuntu/trusty/etc/init.d/graphite-raintank \
  --config-files /etc/graphite-raintank.yaml \
  -d libcairo2 \
  -d "libffi5 | libffi6" \
  --after-install ${DIR}/debian/post-install \
  --before-remove ${DIR}/debian/pre-remove \
  --after-remove ${DIR}/debian/post-remove \
  --url https://github.com/raintank/graphite-raintank \
  --description 'Graphite-web, without the interface. Just the rendering HTTP API. (raintank fork)' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} usr etc
