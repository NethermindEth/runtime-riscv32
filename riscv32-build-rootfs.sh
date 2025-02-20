#!/bin/bash
export TOP_DIR="$(cd "$(dirname "$(which "$0")")" ; pwd -P)"

pushd "${TOP_DIR}" > /dev/null 2> /dev/null
./eng/common/cross/build-rootfs.sh riscv32 buildroot --skipunmount --rootfsdir $(pwd)/crossrootfs/riscv32
popd > /dev/null 2> /dev/null
