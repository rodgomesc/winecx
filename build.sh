#!/usr/bin/env arch -x86_64 bash

# this is a modified version of the build.sh script from https://github.com/Gcenx/crossover-wine-ci project
# huge thanks to Gcenx for the original script

set -e

printtag() {
    # GitHub Actions tag format
    echo "::$1::${2-}"
}

begingroup() {
    printtag "group" "$1"
}

endgroup() {
    printtag "endgroup"
}

export GITHUB_WORKSPACE=$(pwd)

if [ -z "$WINE_VERSION" ]; then
    export WINE_VERSION=9.0-patched
    echo "WINE_VERSION not set building wine-${WINE_VERSION}"
fi


# directories / files inside the downloaded tar file directory structure
export WINE_CONFIGURE=$GITHUB_WORKSPACE/configure

# build directories
export BUILDROOT=$GITHUB_WORKSPACE/build

# target directory for installation
export INSTALLROOT=$GITHUB_WORKSPACE/install
export PACKAGE_UPLOAD=$GITHUB_WORKSPACE/upload

# artifact name
export WINE_INSTALLATION=wine-cx${WINE_VERSION}


export CC="ccache clang"
export CXX="${CC}++"
export CPATH=/usr/local/include
export LIBRARY_PATH=/usr/local/lib
export MACOSX_DEPLOYMENT_TARGET=10.15
export CROSSCFLAGS="-g -O2"
export CFLAGS="${CROSSCFLAGS} -Wno-deprecated-declarations -Wno-format"
export LDFLAGS="-Wl,-headerpad_max_install_names -Wl,-rpath,@loader_path/../../ -Wl,-rpath,/usr/local/lib"

export ac_cv_lib_soname_vulkan=""


begingroup "copying distversion.h..."
cp ${GITHUB_WORKSPACE}/distversion.h ${GITHUB_WORKSPACE}/include/distversion.h
endgroup

begingroup "patching programs/winedbg/resource.h"
sed -i '' 's/#include "distversion.h"/#include <distversion.h>/g' "programs/winedbg/resource.h"
endgroup



mkdir -p ${BUILDROOT}/wine-${WINE_VERSION}
pushd ${BUILDROOT}/wine-${WINE_VERSION}
${WINE_CONFIGURE} \
    --prefix= \
    --disable-tests \
    --enable-archs=i386,x86_64 \
    --enable-win64 \
    --without-alsa \
    --without-capi \
    --with-coreaudio \
    --with-cups \
    --without-dbus \
    --without-fontconfig \
    --with-freetype \
    --with-gettext \
    --without-gettextpo \
    --without-gphoto \
    --with-gnutls \
    --without-gssapi \
    --without-gstreamer \
    --without-inotify \
    --without-krb5 \
    --with-mingw \
    --without-netapi \
    --with-opencl \
    --with-opengl \
    --without-oss \
    --with-pcap \
    --with-pthread \
    --without-pulse \
    --without-sane \
    --with-sdl \
    --without-udev \
    --with-unwind \
    --without-usb \
    --without-v4l2 \
    --with-vulkan \
    --without-x
popd




pushd ${BUILDROOT}/wine-${WINE_VERSION}
make -j$(sysctl -n hw.ncpu 2>/dev/null)
popd


pushd ${BUILDROOT}/wine-${WINE_VERSION}
make install-lib DESTDIR="${INSTALLROOT}/${WINE_INSTALLATION}"
popd



pushd ${INSTALLROOT}
tar -czvf ${WINE_INSTALLATION}.tar.gz ${WINE_INSTALLATION}
popd




mkdir -p ${PACKAGE_UPLOAD}
cp ${INSTALLROOT}/${WINE_INSTALLATION}.tar.gz ${PACKAGE_UPLOAD}/

