# to generate the SSL certs:
# openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -extensions v3_ca \
#    -keyout ssl_bump.pem -out ssl_bump.crt

# to build the container
# docker build . -t ubuntu-squid

mkdir $(pwd)/squid_cache

docker run -it -p 3128:3128 --rm \
    -v $(pwd)/squid_cache:/var/cache/squid4 \
    -v $(pwd)/ssl_bump.pem:/ssl_bump.pem:ro -v $(pwd)/ssl_bump.crt:/ssl_bump.crt:ro \
    -e MITM_CERT=/ssl_bump.crt \
    -e MITM_KEY=/ssl_bump.pem \
    -e MITM_PROXY=yes \
    -e EXTRA_CONFIG_0="" \
    ubuntu-squid


