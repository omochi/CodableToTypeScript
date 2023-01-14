#!/bin/bash
set -ueo pipefail

SWIFT_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-5.7-SNAPSHOT-2023-01-09-a/swift-wasm-5.7-SNAPSHOT-2023-01-09-a-ubuntu20.04_x86_64.tar.gz"
BINARYEN_URL="https://github.com/WebAssembly/binaryen/releases/download/version_111/binaryen-version_111-x86_64-linux.tar.gz"
WABT_URL="https://github.com/WebAssembly/wabt/releases/download/1.0.32/wabt-1.0.32-ubuntu.tar.gz"

set -x

sudo apt-get -q update
sudo apt-get -q install \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4 \
    libedit2 \
    libgcc-9-dev \
    libpython2.7 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2 \
    libz3-dev \
    pkg-config \
    tzdata \
    uuid-dev \
    zlib1g-dev \
    rsync \
    build-essential

mkdir -p temp
cd temp

curl -sLo swift.tar.gz "$SWIFT_URL"
tar zxf swift.tar.gz
sudo mkdir -p /swiftwasm
sudo rsync -rlpt swift-wasm-5.7-SNAPSHOT-2023-01-09-a/ /swiftwasm
export PATH="/swiftwasm/usr/bin:$PATH"

curl -sLo binaryen.tar.gz "$BINARYEN_URL"
tar xzf binaryen.tar.gz
sudo rsync -rlpt binaryen-version_111/ /usr/local

curl -sLo wabt.tar.gz "$WABT_URL"
tar xzf wabt.tar.gz
sudo rsync -rlpt wabt-1.0.32/ /usr/local

cd ..

npm install
npm run swiftbuild
npm run build
