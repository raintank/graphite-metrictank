#!/bin/bash
set -x
# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
: ${BUILD_ROOT:="${DIR}/build"}

if [ -z ${PACKAGECLOUD_REPO} ] ; then
  echo "The environment variable PACKAGECLOUD_REPO must be set."
  exit 1
fi

package_cloud push ${PACKAGECLOUD_REPO}/debian/wheezy ${BUILD_ROOT}/pkg/debian/wheezy/*.deb
package_cloud push ${PACKAGECLOUD_REPO}/debian/jessie ${BUILD_ROOT}/pkg/debian/jessie/*.deb
package_cloud push ${PACKAGECLOUD_REPO}/ubuntu/trusty ${BUILD_ROOT}/pkg/ubuntu/trusty/*.deb
package_cloud push ${PACKAGECLOUD_REPO}/ubuntu/xenial ${BUILD_ROOT}/pkg/ubuntu/xenial/*.deb
package_cloud push ${PACKAGECLOUD_REPO}/el/6 ${BUILD_ROOT}/pkg/centos/6/*.rpm
package_cloud push ${PACKAGECLOUD_REPO}/el/7 ${BUILD_ROOT}/pkg/centos/7/*.rpm
