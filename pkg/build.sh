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
	$SUDO yum -y install python python-devel gcc gcc-c++ make openssl-devel libffi-devel cairo-devel git
fi
$SUDO pip install virtualenv virtualenv-tools

# remove any existing BUILD_DIR
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cp -a ${DIR}/$DISTRO/$VERSION/* ${BUILD_DIR}/
mkdir -p ${BUILD_DIR}/usr/share/python

virtualenv ${BUILD_DIR}/usr/share/python/graphite

${BUILD_DIR}/usr/share/python/graphite/bin/pip install ${REPO_PREFIX}/graphite-api.git
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


