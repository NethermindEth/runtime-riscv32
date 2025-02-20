#!/bin/bash
export TOP_DIR="$(cd "$(dirname "$(which "$0")")" ; pwd -P)"

pushd "${TOP_DIR}" > /dev/null 2> /dev/null
./src/coreclr/build-runtime.sh -cross -riscv32
popd > /dev/null 2> /dev/null
