#!/usr/bin/env bash
# Build SQLite for OHOS ARM64
set -ex

DEPS_DIR=/opt/deps
WORKDIR=/home/runner/work/ohos-python-builder/ohos-python-builder

if [ -f $DEPS_DIR/lib/libsqlite3.so ]; then
    echo "=== sqlite already built, skipping ==="
    exit 0
fi

cd $WORKDIR/deps 2>/dev/null || { mkdir -p $WORKDIR/deps && cd $WORKDIR/deps; }

if [ ! -d sqlite-autoconf-3510200 ]; then
    curl -fLO https://www.sqlite.org/2024/sqlite-autoconf-3450100.tar.gz
    tar -zxf sqlite-autoconf-3510200.tar.gz
    rm -rf sqlite-autoconf-3510200.tar.gz
fi

cd sqlite-autoconf-3510200
./configure --host=aarch64-linux-gnu --build=x86_64-linux-gnu --prefix=$DEPS_DIR \
    --disable-readline
make -j$(nproc)
make install

echo "=== sqlite build complete ==="
