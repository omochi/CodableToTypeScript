#!/bin/bash
set -ueo pipefail

SWIFT_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-5.7-SNAPSHOT-2023-01-09-a/swift-wasm-5.7-SNAPSHOT-2023-01-09-a-ubuntu20.04_x86_64.tar.gz"
BINARYEN_URL="https://github.com/WebAssembly/binaryen/releases/download/version_111/binaryen-version_111-x86_64-linux.tar.gz"
WABT_URL="https://github.com/WebAssembly/wabt/releases/download/1.0.32/wabt-1.0.32-ubuntu.tar.gz"

set -x

apt-get update
apt-get install \
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
    zlib1g-dev

mkdir -p temp
cd temp

curl -o swift.tar.gz -L "$SWIFT_URL"
tar zxfk swift.tar.gz -C / --strip-components 1

curl -o binaryen.tar.gz -L "$BINARYEN_URL"
tar xzfk binaryen.tar.gz -C / --strip-components 1

curl -o wabt.tar.gz -L "$WABT_URL"
tar xzfk wabt.tar.gz -C / --strip-components 1

cd ..

npm install
npm run swiftbuild
npm run build
