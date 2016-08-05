#!/bin/bash

# Find the directory we exist within
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
: ${BUILD_ROOT:="${DIR}/build"}

if [ -z ${PACKAGECLOUD_REPO} ] ; then
  echo "The environment variable PACKAGECLOUD_REPO must be set."
  exit 1
fi

package_cloud push ${PACKAGECLOUD_REPO}/debian/wheezy ${BUILD_ROOT}/sysvinit/*deb
package_cloud push ${PACKAGECLOUD_REPO}/debian/jessie ${BUILD_ROOT}/systemd/*deb
package_cloud push ${PACKAGECLOUD_REPO}/ubuntu/trusty ${BUILD_ROOT}/upstart/*deb
package_cloud push ${PACKAGECLOUD_REPO}/ubuntu/xenial ${BUILD_ROOT}/systemd/*deb
package_cloud push ${PACKAGECLOUD_REPO}/el/6 ${BUILD_ROOT}/upstart-0.6.5/*rpm
package_cloud push ${PACKAGECLOUD_REPO}/el/7 ${BUILD_ROOT}/systemd-centos7/*rpm
