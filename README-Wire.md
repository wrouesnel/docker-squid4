This repo (cloned from https://github.com/fgrehm/squid3-ssl-docker) contains instructions and tools for setting up a transparent HAPROXY/Squid configuration.
You're going to want to clone it (from https://github.com/wireapp/docker-squid4.git).

This repo contains two directories:

# mk-ca-cert

You'll want to run this to create your man-in-the-middle SSL certificate.
```
cd docker-squid4/mk-ca-cert
./mk-certs
cd ../docker-squid
mkdir -p ./mnt/cert
cp ../mk-ca-cert/certs/private.pem ./mnt/cert/local-mitm-key.pem
cp ../mk-ca-cert/certs/wire.com.crt ./mnt/cert/local-mitm-cert.pem
```

# docker-squid
docker-squid consains a modified docker-squid container. It has been modified to build an experimental version of docker from Measurement Factory, and to install and use haproxy.

It requires the use of host based networking by default, but does not assume any IPs (excepting lo at 127.0.0.1).

## Building:

* Make sure you have installed the docker snap.
```
sudo snap install docker
```

### Additional steps for building/running as a user:
If you are building/running as a non-priveledged user (recommended):

* Set up docker to be built as your user. taken from https://superuser.com/questions/835696/how-solve-permission-problems-for-docker-in-ubuntu
```
sudo groupadd docker
sudo gpasswd -a <YOUR_USERNAME_HERE> docker
sudo systemctl restart snap.docker.dockerd
```

* Log out, and log in again to make your group membership active.
TODO: find out what services need to be restarted.
* Reboot, if ubuntu 16.

### Kicking off the build:
* If you followed the previous step, you can run this as the user you used, in that step. otherwise, as root:
```sh
cd docker-squid4/docker-squid
docker build .
```

* When this completes, it will give you an image ID on the last line of output, which will look like ```Successfully built fd0a530f522a```. Set a tag refering to that image ID, so our run script can launch the image.
```
docker tag <image_id> squid
```

* Edit run.sh. comment out the current IMG_TAG, and add a new line:
```
IMG_TAG=squid
```

## Downloading:
Alternatively, you can pull our most recent build from quay.io/wire:

```sh
export SQUID_SHA256=0df70cbcd1faa7876e89d65d215d86e1518cc45e24c7bf8891bc1b57563961fa
docker pull quay.io/wire/squid@sha256:$SQUID_SHA256
docker inspect --format='{{index .RepoDigests 0}}' quay.io/wire/squid@sha256:$SQUID_SHA256 \
  | grep -q $SQUID_SHA256 && echo 'OK!' || echo '*** error: wrong checksum!'
docker tag quay.io/wire/squid@sha256:$SQUID_SHA256 squid
```

## Using

* Once you have either built and tagged your image, or downloaded an image, you can launch the image with run.sh:
```
./run.sh
```

* In order for transparent services to be available, you have to run the "/root/sbin/iptables" script, from the wire-server-deploy-networkless instructions:
```
sudo /root/sbin/iptables
```
* Please note that the interface name in this file must be correct, and may need changed if the interface you are providing services on is not 'ens4'.

# interpreting squid's access.log to export info on cache.

docker-squid/mnt/log/access.log can be used to extract things like
domain lists and cache TOC.  basic info in json:

```bash
cat mnt/log/access.log | \
  perl -ne '/^\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)\s/; print "{\"size\":$1,\"verb\":\"$2\",\"uri\":\"$3\"},\n"'
```

You can put the resulting output into a file, add '[', ']' around it and use it as input for [./parse-accesslog.hs](./parse-accesslog.hs).

# keeping track of dns queries on VMs

```bash
perl -ne '/dnsmasq.*query\[\w+\]\s+(\S+)\sfrom/ && print "$1\n"' /var/log/syslog | sort | uniq
```

# how to set an explicit/visible proxy to various bits of software:

#### many things

```sh
export http_proxy=http://10.0.0.1:3128/
export https_proxy=http://10.0.0.1:3128/
```

Process variables will be picked up by some programs, but not all.
The remainder of this section lists some exceptions and how to deal
with them.

#### apt (ubuntu)

```sh
echo 'Acquire::http::Proxy "http://10.0.0.1:3128/";' > /etc/apt/apt.conf.d/10proxy
