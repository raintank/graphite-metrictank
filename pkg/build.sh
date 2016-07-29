#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

: ${BUILD_DIR:="${DIR}/build"}
: ${API_BRANCH:="master"}
: ${CIRCLE_BRANCH:="master"}
: ${REPO_PREFIX:="git+https://github.com/raintank"}

# remove any existing BUILD_DIR
rm -rf ${BUILD_DIR} $DIR/tmp
mkdir -p $DIR/tmp

wget -O $DIR/tmp/pypy-5.1.1-linux64.tar.bz2 https://bitbucket.org/pypy/pypy/downloads/pypy-5.1.1-linux64.tar.bz2
tar -C $DIR/tmp -jxf $DIR/tmp/pypy-5.1.1-linux64.tar.bz2 
cd $DIR/tmp/pypy-5.1.1-linux64/bin/
ln -s pypy python
cd $DIR
mkdir -p ${BUILD_DIR}/usr/share/python

virtualenv --always-copy -p $DIR/tmp/pypy-5.1.1-linux64/bin/python ${BUILD_DIR}/usr/share/python/graphite
rsync -avhu $DIR/tmp/pypy-5.1.1-linux64/ $BUILD_DIR/usr/share/python/graphite/
cd ${BUILD_DIR}/usr/share/python/graphite/bin
rm libpypy-c.so
cp $DIR/tmp/pypy-5.1.1-linux64/bin/libpypy-c.so .
cd $DIR

${BUILD_DIR}/usr/share/python/graphite/bin/pip install -U setuptools pip distribute virtualenv-tools
${BUILD_DIR}/usr/share/python/graphite/bin/pip uninstall -y distribute

${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-api.git@${API_BRANCH}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install graphite-api[sentry,cyanite] gunicorn==18.0
${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-metrictank.git@${CIRCLE_BRANCH}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install eventlet
${BUILD_DIR}/usr/share/python/graphite/bin/pip install git+https://github.com/woodsaj/pystatsd.git
${BUILD_DIR}/usr/share/python/graphite/bin/pip install Flask-Cache
${BUILD_DIR}/usr/share/python/graphite/bin/pip install python-memcached

find ${BUILD_DIR} ! -perm -a+r -exec chmod a+r {} \;

mkdir -p ${BUILD_DIR}/usr/share/python/graphite/lib
cd ${BUILD_DIR}/usr/share/python/graphite/lib
ln -s ../lib-python/2.7 python2.7
cd ..
${BUILD_DIR}/usr/share/python/graphite/bin/virtualenv-tools --update-path /usr/share/python/graphite

find ${BUILD_DIR} -iname *.pyc -exec rm {} \;
find ${BUILD_DIR} -iname *.pyo -exec rm {} \;

#mkdir -p ${BUILD_DIR}/etc
cp -a ${DIR}/config ${BUILD_DIR}/etc

