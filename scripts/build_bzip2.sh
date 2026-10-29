#!/usr/bin/env bash
# Build bzip2 for OHOS ARM64
set -ex

DEPS_DIR=/opt/deps
WORKDIR=/home/runner/work/ohos-python-builder/ohos-python-builder

if [ -f $DEPS_DIR/lib/libbz2.so ]; then
    echo "=== bzip2 already built, skipping ==="
    exit 0
fi

cd $WORKDIR/deps 2>/dev/null || { mkdir -p $WORKDIR/deps && cd $WORKDIR/deps; }

if [ ! -d bzip2-1.0.8 ]; then
    curl -fLO https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
    tar -zxf bzip2-1.0.8.tar.gz
    rm -rf bzip2-1.0.8.tar.gz
fi

cd bzip2-1.0.8

# bzip2 doesn't have configure, use make directly
# Build shared library
make -j$(nproc) CC="/bin/clang" CFLAGS="$CFLAGS -fPIC" libbz2.so.1.0.8

# Create symlinks
ln -sf libbz2.so.1.0.8 libbz2.so.1.0
ln -sf libbz2.so.1.0.8 libbz2.so.1
ln -sf libbz2.so.1.0.8 libbz2.so

# Install
mkdir -p $DEPS_DIR/lib $DEPS_DIR/include
cp libbz2.so* $DEPS_DIR/lib/
cp bzlib.h $DEPS_DIR/include/
cp -a libbz2.a $DEPS_DIR/lib/ 2>/dev/null || true

echo "=== bzip2 build complete ==="
