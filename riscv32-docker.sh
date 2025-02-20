#!/bin/bash
export TOP_DIR="$(cd "$(dirname "$(which "$0")")" ; pwd -P)"

pushd "${TOP_DIR}" > /dev/null 2> /dev/null
image="$(docker build -q --build-arg "HOME_PATH=$(pwd)" -f riscv32-Dockerfile .)"
if [ "$?" != "0" ] ; then
    echo "Docker build failed" >&2
    exit 1
fi

docker run -e ROOTFS_DIR=$(pwd)/crossrootfs/riscv32 -v$(pwd):$(pwd) -w $(pwd) --rm -it ${image} $@
ret_code="$?"
popd > /dev/null 2> /dev/null
exit $ret_code
