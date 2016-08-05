#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
SOURCEDIR=$(readlink -e ${DIR}/..)
BUILDDIR=${DIR}/build
build_target()
{
	DISTRO=$1
	VERSION=$2
	docker run --rm -v $SOURCEDIR:/opt/graphite-raintank $DISTRO:$VERSION /opt/graphite-raintank/pkg/build.sh $DISTRO $VERSION
}

for target in debian:wheezy debian:jessie ubuntu:trusty ubuntu:xenial centos:6 centos:7; do
	_distro=${target%:*}
    _version=${target#*:}
    build_target $_distro $_version
done

