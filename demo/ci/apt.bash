#!/bin/bash
set -ueo pipefail

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
    build-essential \
    cmake
