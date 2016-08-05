#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
SOURCEDIR=${DIR}/..
: ${BUILD_DIR:="${DIR}/build"}
: ${API_BRANCH:="master"}
: ${CIRCLE_BRANCH:="master"}
: ${REPO_PREFIX:="git+https://github.com/raintank"}

# remove any existing BUILD_DIR
rm -rf ${BUILD_DIR}

mkdir -p ${BUILD_DIR}/usr/share/python

virtualenv ${BUILD_DIR}/usr/share/python/graphite
${BUILD_DIR}/usr/share/python/graphite/bin/pip install -U pip distribute
${BUILD_DIR}/usr/share/python/graphite/bin/pip uninstall -y distribute

${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-api.git@${API_BRANCH}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install gunicorn==18.0
${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${SOURCEDIR}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install eventlet
${BUILD_DIR}/usr/share/python/graphite/bin/pip install git+https://github.com/woodsaj/pystatsd.git
${BUILD_DIR}/usr/share/python/graphite/bin/pip install Flask-Cache
${BUILD_DIR}/usr/share/python/graphite/bin/pip install python-memcached
${BUILD_DIR}/usr/share/python/graphite/bin/pip install blist

find ${BUILD_DIR} ! -perm -a+r -exec chmod a+r {} \;

cd ${BUILD_DIR}/usr/share/python/graphite
virtualenv-tools --update-path /usr/share/python/graphite

#mkdir -p ${BUILD_DIR}/etc
cp -a ${DIR}/config/common ${BUILD_DIR}/common

