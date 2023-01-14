#!/bin/bash
set -uexo pipefail

mkdir -p temp && cd temp

git clone --recursive "https://github.com/WebAssembly/wabt"
cd wabt
git switch -d 1.0.32 --recurse-submodules
mkdir build
cd build
cmake ..
cmake --build . -j8
sudo make install
