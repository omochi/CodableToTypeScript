#!/bin/bash
set -uexo pipefail

WABT_URL="https://github.com/WebAssembly/wabt/releases/download/1.0.32/wabt-1.0.32-ubuntu.tar.gz"

mkdir -p temp && cd temp

curl -sLo wabt.tar.gz "$WABT_URL"
tar xzf wabt.tar.gz
sudo rsync -rlpt wabt-1.0.32/ /usr/local
