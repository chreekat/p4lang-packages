#!/bin/bash

set -e

: ${DEVEL:=false}

CONTAINER_ENGINE=$(which podman 2>/dev/null || which docker 2>/dev/null)
if [[ -z "$CONTAINER_ENGINE" ]]; then
    echo "Please install Podman or Docker"
    exit 1
fi


if [[ "$DEVEL" != true ]]; then
    $CONTAINER_ENGINE build -t p4lang-packages .
    mkdir -p build/

    for target in pi bmv2 p4c; do
        if [[ $# -gt 0 ]] && [[ "$target" != "$1" ]]; then
            continue
        fi
        $CONTAINER_ENGINE run \
            --rm \
            --mount type=bind,source="$(pwd)/build",target=/mnt \
            p4lang-packages \
            bash -c "make ${target}-sdeb && dpkg -c *.deb && mv *.build *.buildinfo *.changes *.deb *.debian.tar.xz *.dsc *.orig.tar.gz /mnt";
    done
else
    $CONTAINER_ENGINE run \
        -it \
        --mount type=bind,source="$(pwd)",target=/mnt \
        --workdir /mnt \
        p4lang-packages \
        bash
fi
