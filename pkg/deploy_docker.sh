#!/bin/bash

set -x
# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=`git describe --always`

docker push raintank/graphite-metrictank:$VERSION
docker push raintank/graphite-metrictank:latest
