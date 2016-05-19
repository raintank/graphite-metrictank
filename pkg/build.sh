#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${NAME:="graphite-raintank"}
: ${VERSION:=1.0.1}
: ${BUILD_DIR:="${DIR}/build"}
: ${API_BRANCH:="master"}
: ${CIRCLE_BRANCH:="master"}
: ${REPO_PREFIX:="git+https://github.com/raintank"}

# remove any existing BUILD_DIR
rm -rf ${BUILD_DIR} $DIR/tmp
mkdir -p $DIR/tmp

wget -O $DIR/tmp/pypy-5.1.1-linux64.tar.bz2 https://bitbucket.org/pypy/pypy/downloads/pypy-5.1.1-linux64.tar.bz2
tar -C $DIR/tmp -jxf $DIR/tmp/pypy-5.1.1-linux64.tar.bz2 

mkdir -p ${BUILD_DIR}/usr/share/python

virtualenv -p $DIR/tmp/pypy-5.1.1-linux64/bin/pypy ${BUILD_DIR}/usr/share/python/graphite

${BUILD_DIR}/usr/share/python/graphite/bin/pip install -U pip distribute
${BUILD_DIR}/usr/share/python/graphite/bin/pip uninstall -y distribute

${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-api.git@${API_BRANCH}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install graphite-api[sentry,cyanite] gunicorn==18.0
${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-raintank.git@${CIRCLE_BRANCH}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install eventlet
${BUILD_DIR}/usr/share/python/graphite/bin/pip install git+https://github.com/woodsaj/pystatsd.git
${BUILD_DIR}/usr/share/python/graphite/bin/pip install Flask-Cache
${BUILD_DIR}/usr/share/python/graphite/bin/pip install python-memcached

find ${BUILD_DIR} ! -perm -a+r -exec chmod a+r {} \;

cd ${BUILD_DIR}/usr/share/python/graphite
virtualenv-tools --update-path /usr/share/python/graphite

find ${BUILD_DIR} -iname *.pyc -exec rm {} \;
find ${BUILD_DIR} -iname *.pyo -exec rm {} \;

#mkdir -p ${BUILD_DIR}/etc
cp -a ${DIR}/config/ubuntu/trusty/etc ${BUILD_DIR}/
