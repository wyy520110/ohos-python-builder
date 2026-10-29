#!/usr/bin/env bash
# Build CPython 3.14.6 for OHOS ARM64
set -ex

DEPS_DIR=/opt/deps
WORKDIR=/home/runner/work/ohos-python-builder/ohos-python-builder
PREFIX=/opt/python-3.14.6-ohos-arm64
BUILD_PYTHON=${BUILD_PYTHON:-$(which python3)}

if [ -f $PREFIX/bin/python3.14 ]; then
    echo "=== Python already built, skipping ==="
    exit 0
fi

cd $WORKDIR/deps 2>/dev/null || { mkdir -p $WORKDIR/deps && cd $WORKDIR/deps; }

if [ ! -d Python-3.14.6 ]; then
    curl -fLO https://www.python.org/ftp/python/3.14.6/Python-3.14.6.tgz
    tar -zxf Python-3.14.6.tgz
    rm -rf Python-3.14.6.tgz
fi

cd Python-3.14.6

# Force aarch64-linux-musl platform triplet (reuse musl pip packages)
sed -i 's|PLATFORM_TRIPLET="${PLATFORM_TRIPLET#PLATFORM_TRIPLET=}"|PLATFORM_TRIPLET="aarch64-linux-musl"|g' configure
sed -i 's|MULTIARCH=$($CC --print-multiarch 2>/dev/null)|MULTIARCH="aarch64-linux-musl"|g' configure
sed -i '/def get_platform():/a\    return "linux-aarch64"' Lib/sysconfig/__init__.py
sed -i '/def system():/a\    return "Linux"' Lib/platform.py
echo "PLATFORM_TRIPLET=aarch64-linux-musl" > Misc/platform_triplet.c

# Configure with cross-compiling support
./configure \
    --build=x86_64-linux-gnu \
    --host=aarch64-linux-gnu \
    --prefix=$PREFIX \
    --with-openssl=$DEPS_DIR \
    --disable-ipv6 \
    --with-readline=readline \
    --with-dbmliborder=gdbm \
    --enable-shared \
    --with-build-python=$BUILD_PYTHON \
    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no \
    ac_cv_buggy_getaddrinfo=no \
    LDFLAGS="-L$DEPS_DIR/lib -Wl,-rpath,'\$\$ORIGIN/../lib' -Wl,-rpath,'\$\$ORIGIN/../../../lib'" \
    CC=/bin/clang \
    CXX=/bin/clang++ \
    AR=/bin/llvm-ar \
    RANLIB=/bin/llvm-ranlib \
    LD=/bin/ld.lld \
    CFLAGS="$CFLAGS -DNO_GETTEXT"

make -j$(nproc) || {
    echo "=== First make failed, patching _localemodule ==="
    # Disable _localemodule entirely (gettext not available)
    sed -i '/_localemodule/d' Modules/Setup.local 2>/dev/null || true
    sed -i 's|_locale _localemodule.c|##_locale _localemodule.c|' Modules/Setup.stdlib 2>/dev/null || true
    # Also patch the source to provide stubs
    sed -i '1i\#define textdomain(d) ((char*)(d))\n#define bindtextdomain(d,dir) ((char*)(dir))\n#define gettext(s) (s)\n#define dgettext(d,s) (s)\n#define dcgettext(d,s,c) (s)\n#define ngettext(s,p,n) ((n)==1?(s):(p))\n#define dngettext(d,s,p,n) ((n)==1?(s):(p))\n#define bind_textdomain_codeset(d,c) ((char*)(c))' Modules/_localemodule.c
    make -j$(nproc)
}
make install

# Copy dependency libs
cp $DEPS_DIR/lib/*so* $PREFIX/lib/

echo "=== Python build complete ==="
