#!/bin/bash

set -x

# Setup the ssl_cert directory
if [ ! -d /etc/squid4/ssl_cert ]; then
    mkdir /etc/squid4/ssl_cert
fi

chown -R proxy:proxy /etc/squid4
chmod 700 /etc/squid4/ssl_cert

# Setup the squid cache directory
if [ ! -d /var/cache/squid4 ]; then
    mkdir -p /var/cache/squid4
fi
chown -R proxy: /var/cache/squid4
chmod -R 750 /var/cache/squid4

if [ -n "$MITM_PROXY" ]; then
    if [ -n "$MITM_KEY" ]; then
        echo "Copying \"$MITM_KEY\" as MITM key..."
        cp "$MITM_KEY" /etc/squid4/ssl_cert/mitm.pem
        chown root:proxy /etc/squid4/ssl_cert/mitm.pem
    fi

    if [ -n "$MITM_CERT" ]; then
        echo "Copying \"$MITM_CERT\" as MITM CA..."
        cp "$MITM_CERT" /etc/squid4/ssl_cert/mitm.crt
        chown root:proxy /etc/squid4/ssl_cert/mitm.crt
    fi

    if [ -z "$MITM_CERT" ] || [ -z "$MITM_KEY" ]; then
        echo "Must specify \"$MITM_CERT\" AND \"$MITM_KEY\"." 1>&2
        exit 1
    fi
fi

chown proxy: /dev/stdout
chown proxy: /dev/stderr

# Initialize the certificates database
/usr/libexec/security_file_certgen -c -s /var/spool/squid4/ssl_db -M1000000000
chown -R proxy: /var/spool/squid4/ssl_db

ssl_crtd -c -s
ssl_db

# Build the configuration directories if needed
squid -z -N

# start haproxy
service haproxy start

# run squid!
squid -N
