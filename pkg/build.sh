#!/bin/bash
set -x
# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
SOURCEDIR=${DIR}/..

DISTRO=${1:-ubuntu}
VERSION=${2:-xenial}

BUILD_DIR=${DIR}/build/$DISTRO/$VERSION
REPO_PREFIX=${REPO_PREFIX:-git+https://github.com/raintank}

SUDO=sudo
if [ $(whoami) == "root" ]; then
	SUDO=""
fi
TMP=${SOURCEDIR}/tmp
mkdir -p $TMP

## ensure we have build dependencies installed.
if [ $DISTRO == "ubuntu" ] || [ $DISTRO == "debian" ]; then
	$SUDO apt-get update
	$SUDO apt-get -y install build-essential libffi-dev libcairo2-dev git wget
else
	$SUDO yum -y install gcc gcc-c++ make openssl-devel libffi-devel cairo-devel git wget
fi

if [ ! -d ${TMP}/pypy-5.6-linux_x86_64-portable ]; then
	wget -O ${TMP}/pypy-5.6-linux_x86_64-portable.tar.bz2 https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-5.6-linux_x86_64-portable.tar.bz2
	tar -C ${TMP} -jxf ${TMP}/pypy-5.6-linux_x86_64-portable.tar.bz2
fi

# remove any existing BUILD_DIR
rm -rf ${BUILD_DIR}
cp -a ${TMP}/pypy-5.6-linux_x86_64-portable /usr/share/pypy
mkdir -p ${BUILD_DIR}/var/lib/graphite
mkdir -p ${BUILD_DIR}/var/log/graphite
cp -a ${DIR}/$DISTRO/$VERSION/* ${BUILD_DIR}/
mkdir -p ${BUILD_DIR}/etc/
cp -a $DIR/common/default ${BUILD_DIR}/etc/
cp -a $DIR/common/graphite-metrictank ${BUILD_DIR}/etc/

mkdir -p /usr/share/python
/usr/share/pypy/bin/virtualenv-pypy /usr/share/python/graphite
/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-api.git
/usr/share/python/graphite/bin/pip install twisted
/usr/share/python/graphite/bin/pip install ${SOURCEDIR}
/usr/share/python/graphite/bin/pip install statsd
/usr/share/python/graphite/bin/pip install Flask-Cache
/usr/share/python/graphite/bin/pip install gevent
/usr/share/python/graphite/bin/pip install msgpack-python

mkdir -p ${BUILD_DIR}/usr/share/python/
cp -a /usr/share/python/graphite ${BUILD_DIR}/usr/share/python/
cp -a /usr/share/pypy ${BUILD_DIR}/usr/share/
find ${BUILD_DIR} ! -perm -a+r -exec chmod a+r {} \;

