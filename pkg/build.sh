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

## ensure we have build dependencies installed.
if [ $DISTRO == "ubuntu" ] || [ $DISTRO == "debian" ]; then
	$SUDO apt-get update
	$SUDO apt-get -y install python python-pip build-essential python-dev libffi-dev libcairo2-dev git
else
	$SUDO yum -y install python-setuptools python-devel gcc gcc-c++ make openssl-devel libffi-devel cairo-devel git
	$SUDO easy_install pip
fi
$SUDO pip install virtualenv virtualenv-tools

# remove any existing BUILD_DIR
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}/var/lib/graphite
mkdir -p ${BUILD_DIR}/var/log/graphite
cp -a ${DIR}/$DISTRO/$VERSION/* ${BUILD_DIR}/
mkdir -p ${BUILD_DIR}/etc/
cp -a $DIR/common/default ${BUILD_DIR}/etc/
cp -a $DIR/common/graphite-metrictank ${BUILD_DIR}/etc/
mkdir -p ${BUILD_DIR}/usr/share/python

virtualenv ${BUILD_DIR}/usr/share/python/graphite

${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-api.git
${BUILD_DIR}/usr/share/python/graphite/bin/pip install twisted
${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${SOURCEDIR}
${BUILD_DIR}/usr/share/python/graphite/bin/pip install statsd
${BUILD_DIR}/usr/share/python/graphite/bin/pip install Flask-Cache
${BUILD_DIR}/usr/share/python/graphite/bin/pip install blist
${BUILD_DIR}/usr/share/python/graphite/bin/pip install msgpack-python

find ${BUILD_DIR} ! -perm -a+r -exec chmod a+r {} \;

cd ${BUILD_DIR}/usr/share/python/graphite
virtualenv-tools --update-path /usr/share/python/graphite


