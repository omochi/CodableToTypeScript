#!/bin/bash
set -uexo pipefail
cd "$(dirname "$0")/.."

npm install
npm run swiftbuild
npm run build
