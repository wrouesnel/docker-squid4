#!/bin/bash

#RUN_IN_SHELL="--entrypoint /bin/bash"

NETWORKING="--dns=8.8.8.8 --network=host"
#NETWORKING="-p 3128:3128 -p 3129:3129"

mkdir -p $(pwd)/srv/squid/cache
mkdir -p $(pwd)/etc/ssl/certs
mkdir -p $(pwd)/etc/ssl/private

docker run -it $NETWORKING --rm \
    -v $(pwd)/srv/squid/cache:/var/cache/squid4 \
    -v /etc/ssl/certs:/etc/ssl/certs:ro \
    -v $(pwd)/etc/ssl/private/local_mitm.pem:/local-mitm.pem:ro \
    -v $(pwd)/etc/ssl/certs/local_mitm.pem:/local-mitm.crt:ro \
    -e MITM_CERT=/local-mitm.crt \
    -e MITM_KEY=/local-mitm.pem \
    -e MITM_PROXY=yes \
    -e MAX_OBJECT_SIZE="100000 MB" \
    -e MEM_CACHE_SIZE="1000000 MB" \
    ${RUN_IN_SHELL} \
    squid
