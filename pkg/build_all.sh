#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
SOURCEDIR=$(readlink -e ${DIR}/..)
BUILDDIR=${DIR}/build
mkdir -p $BUILDDIR
TARGETS=${1:-debian:wheezy debian:jessie ubuntu:trusty ubuntu:xenial centos:6 centos:7}
build_target()
{
	DISTRO=$1
	VERSION=$2
	docker run --rm -v $SOURCEDIR:/opt/graphite-metrictank $DISTRO:$VERSION /opt/graphite-metrictank/pkg/build.sh $DISTRO $VERSION
}

for target in $TARGETS; do
	_distro=${target%:*}
    _version=${target#*:}
    build_target $_distro $_version
done

