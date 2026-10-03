#!/bin/bash
# Runs as the gem5 user in the guest. ISA=x86|arm64.
set -eu

APPS="blackscholes bodytrack canneal dedup facesim ferret fluidanimate freqmine raytrace streamcluster swaptions vips x264"
CONFIG=gcc-hooks-gem5-fs

cd /home/gem5
tar -xzf parsec-src.tar.gz
cd parsec-benchmark
bash /home/gem5/add-gem5-bldconfs.sh "$PWD"

export GEM5_ROOT=/home/gem5/gem5 M5_ARCH=$ISA
# Empty --build/--host break libtool's configure.
export GNU_HOST_NAME=$(gcc -dumpmachine) GNU_TARGET_NAME=$(gcc -dumpmachine)
set +u # env.sh reads unset variables
source env.sh
set -u
parsecmgmt -a build -p $APPS -c "$CONFIG"

# Never ship an image that is silently missing an app.
for app in $APPS; do
    ls pkgs/*/"$app"/inst/*."$CONFIG"/bin/* > /dev/null \
        || { echo "missing binary for $app" >&2; exit 1; }
done
