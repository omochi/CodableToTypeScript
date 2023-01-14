#!/bin/bash
set -uexo pipefail

SWIFT_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-5.7-SNAPSHOT-2023-01-09-a/swift-wasm-5.7-SNAPSHOT-2023-01-09-a-ubuntu20.04_x86_64.tar.gz"

mkdir -p temp && cd temp

curl -sLo swift.tar.gz "$SWIFT_URL"
tar zxf swift.tar.gz
sudo mkdir -p /swiftwasm
sudo rsync -rlpt swift-wasm-5.7-SNAPSHOT-2023-01-09-a/ /swiftwasm

echo "/swiftwasm/usr/bin" >> "$GITHUB_PATH"
