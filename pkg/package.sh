#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${NAME:="graphite-metrictank"}
: ${BUILD_DIR:="${DIR}/build"}
VERSION="$(git describe --long)"
ARCH="$(uname -m)"
PACKAGE_NAME="${DIR}/artifacts/${NAME}-${VERSION}_${ARCH}.deb"

fpm \
  -t deb -s dir -C ${BUILD_DIR} -n ${NAME} -v $VERSION \
  --deb-default ${DIR}/config/ubuntu/trusty/etc/default/graphite-metrictank \
  --deb-init ${DIR}/config/ubuntu/trusty/etc/init.d/graphite-metrictank \
  --config-files /etc/graphite-metrictank.yaml \
  -d libcairo2 \
  -d "libffi5 | libffi6" \
  --after-install ${DIR}/debian/post-install \
  --before-remove ${DIR}/debian/pre-remove \
  --after-remove ${DIR}/debian/post-remove \
  --url https://github.com/raintank/graphite-metrictank \
  --description 'Graphite-web, without the interface. Just the rendering HTTP API. (raintank fork)' \
  --license 'Apache 2.0' \
  -p ${PACKAGE_NAME} usr etc
