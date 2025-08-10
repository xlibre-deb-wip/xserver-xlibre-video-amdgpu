#!/bin/bash

set -e
set -o xtrace

echo 'deb-src https://deb.debian.org/debian bookworm main' >/etc/apt/sources.list.d/deb-src.list
echo "deb [trusted=yes] https://gitlab.freedesktop.org/gfx-ci/ci-deb-repo/-/raw/${PKG_REPO_REV}/ ${FDO_DISTRIBUTION_VERSION%-*} main" | tee /etc/apt/sources.list.d/gfx-ci_.list

apt-get update
apt-get install -y git ca-certificates build-essential automake autoconf libtool pkg-config

echo 'APT::Get::Build-Dep-Automatic "true";' >>/etc/apt/apt.conf
apt-get build-dep -y xorg-server

git clone https://gitlab.freedesktop.org/xorg/lib/libXfont.git
cd libXfont
git checkout libXfont-1.5-branch
./autogen.sh
make install-pkgconfigDATA
cd .. && rm -rf libXfont

git clone https://gitlab.freedesktop.org/xorg/xserver.git
cd xserver

for VERSION in 1.13 1.14 1.15; do
    git checkout server-${VERSION}-branch
    # Workaround glvnd having reset the version in gl.pc from what Mesa used
    # similar to xserver commit e6ef2b12404dfec7f23592a3524d2a63d9d25802
    sed -i -e 's/gl >= [79].[12].0/gl >= 1.2/' configure.ac
    ./autogen.sh --prefix=/usr/local/xserver-$VERSION --enable-dri2 --disable-dmx
    make -C include install-nodist_sdkHEADERS
    make install-headers install-aclocalDATA install-pkgconfigDATA clean
    git restore configure.ac
done

for VERSION in 1.16 1.17 1.18 1.19 1.20 21.1; do
    git checkout server-${VERSION}-branch
    # Workaround glvnd having reset the version in gl.pc from what Mesa used
    # similar to xserver commit e6ef2b12404dfec7f23592a3524d2a63d9d25802
    sed -i -e 's/gl >= [79].[12].0/gl >= 1.2/' configure.ac
    ./autogen.sh --prefix=/usr/local/xserver-$VERSION --enable-dri2 --enable-dri3 --enable-glamor --disable-dmx
    make -C include install-nodist_sdkHEADERS
    make install-headers install-aclocalDATA install-pkgconfigDATA clean
    git restore configure.ac
done

apt-get install -y clang xutils-dev libdrm-dev libgl1-mesa-dev libgbm-dev libudev-dev \
        x11proto-dev libpixman-1-dev libpciaccess-dev mesa-common-dev libxcvt-dev
apt-get purge -y git ca-certificates
apt-get autoremove -y --purge
