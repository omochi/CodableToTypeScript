#!/bin/bash
set -uexo pipefail

BINARYEN_URL="https://github.com/WebAssembly/binaryen/releases/download/version_111/binaryen-version_111-x86_64-linux.tar.gz"

mkdir -p temp && cd temp

curl -sLo binaryen.tar.gz "$BINARYEN_URL"
tar xzf binaryen.tar.gz
sudo rsync -rlpt binaryen-version_111/ /usr/local
