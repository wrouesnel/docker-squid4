This repo (cloned from https://github.com/fgrehm/squid3-ssl-docker) contains two directories:

# mk-ca-cert

You'll want to run this to create your man-in-the-middle SSL certificate.
```
cd docker-squid4/mk-ca-certs
./mk-certs
cd ../docker-squid
mkdir -p ./etc/ssl/private/
mkdir -p ./etc/ssl/certs
cp certs/private.pem ./etc/ssl/private/local_mitm.pem
cp certs/wire.com.crt ./etc/ssl/certs/local_mitm.pem
```

# docker-squid
docker-squid consains a modified docker-squid container. It has been modified to build an experimental version of docker from Measurement Factory, and to install and use haproxy.

It assumes that your internal network is 10.0.0.0ish.

to build:

```sh
docker build .
```

When this completes, it will give you an image ID on the last line of output, which will look like ```Successfully built fd0a530f522a```. Set a tag refering to that image ID, so our run script can launch the image.
```
docker tag <image_id> squid
```

Alternatively, you can pull it from quay.io/wire:

```sh
export SQUID_SHA256=3c6af3b48ca03f134aad4f5aeb6eaee8093dbc185a874683cdb6f67a252124b8
docker pull quay.io/wire/squid@sha256:$SQUID_SHA256
docker inspect --format='{{index .RepoDigests 0}}' quay.io/wire/squid@sha256:$SQUID_SHA256 \
  | grep -q $SQUID_SHA256 && echo 'OK!' || echo '*** error: wrong checksum!'
docker tag quay.io/wire/squid@sha256:$SQUID_SHA256 squid
```

You can now launch the image with run.sh

```
./run.sh
```
