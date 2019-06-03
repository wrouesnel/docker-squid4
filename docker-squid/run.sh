#!/bin/bash

set -ex

IMG_TAG=quay.io/wire/squid@sha256:0df70cbcd1faa7876e89d65d215d86e1518cc45e24c7bf8891bc1b57563961fa

#RUN_IN_SHELL="--entrypoint /bin/bash"

NETWORKING="--dns=8.8.8.8 --network=host"
#NETWORKING="-p 3128:3128 -p 3129:3129"

SETUP_TLS="
    -v /etc/ssl/certs:/etc/ssl/certs:ro"

test -e ./mnt/cert/local-mitm-cert.pem || exit 1
test -e ./mnt/cert/local-mitm-key.pem || exit 1
SETUP_MITM="
    -e MITM_PROXY=yes
    -e MITM_CERT=/mnt/cert/local-mitm-cert.pem
    -e MITM_KEY=/mnt/cert/local-mitm-key.pem"

mkdir -p ./mnt/cache/
mkdir -p ./mnt/log/
SETUP_CFG="
    -v $(pwd)/mnt/:/mnt/"

docker run -it --rm \
       ${RUN_IN_SHELL} \
       ${NETWORKING} \
       ${SETUP_TLS} \
       ${SETUP_MITM} \
       ${SETUP_CFG} \
       ${IMG_TAG}
