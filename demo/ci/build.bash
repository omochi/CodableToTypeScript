#!/bin/bash
set -uexo pipefail
cd "$(dirname "$0")/.."

swift build --product C2TS --triple wasm32-unknown-wasi -c release
wasm-opt -Os .build/release/C2TS.wasm -o public/C2TS.wasm
wasm-strip public/C2TS.wasm

npm install
npm run build
