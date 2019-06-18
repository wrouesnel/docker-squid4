# Status

Highly experimental!

This is a fork of https://github.com/wrouesnel/docker-squid4 that has
been tested for very specific parameters only.

See also: [README-Wire.md](./README-Wire.md)

# Quicklinks

- [upstream](https://github.com/wireapp/docker-squid4)
- [alternative to docker-squid4](https://github.com/sonertari/SSLproxy/blob/master/NEWS.md)
- [alternative to squid](https://smithproxy.org/)
- [alternative to squid](https://github.com/sonertari/SSLproxy)
- [squid homepage](http://www.squid-cache.org/)
- [squid source](https://github.com/squid-cache/squid)
- [haproxy homepage](http://www.haproxy.org/)
- [blog post](https://blog.mailchannels.com/using-transport-layer-security-tls-with-a-transparent-smtp-proxy)
- [blog post](https://tektab.com/2012/09/28/squid-transparent-proxy-for-https-ssl-traffic/)
- [magazine article (german)](https://www.pcwelt.de/ratgeber/Mit-Squid-als-Proxy-Server-schneller-im-Netzwerk-surfen-5896242.html)

# Squid4 with SSL proxying

This dockerfile builds a Squid 4 instance and includes all the necessary
tooling to run it as a MITM (man-in-the-middle) SSL proxy.

There's a number of reasons to do this - the big one being optimizing caching
and delivery of objects during docker builds which might be downloading them
from SSL protected endpoints.

It will require you to generate your own CA and set it as trusted.

The resulting docker image uses the following configuration environment
variables:

 * `HTTP_PORT`
    Default: `3128`
 * `ICP_PORT`
    If set, enables ICP on the given port for all users.
 * `HTCP_PORT`
    If set, enables HTCP on the given port for all users.
 * `MITM_PROXY`
    If set, tries to enable MITM SSL proxy functionality (requires CERT and KEY)
 * `MITM_CERT`
    If set, the given PEM certificate is copied and used as the CA authority for
    MITM'ing connections.
 *  `MITM_KEY`
    If set, the given PEM certificate is copied and used as the signing key for
    the MITM CA.
 * `VISIBLE_HOSTNAME`
    Default: `docker-squid4`
    Should be set to a unique value if you are chaining multiple proxy servers.
 * `MAX_CACHE_SIZE`
    Default: `40000`
    Cache size in megabytes. The cache defaults to `/var/cache/squid4`. You
    should mount a volume here to make it persistent.
 * `MAX_OBJECT_SIZE`
    Default `"1536 MB"`
    Maximum object size to store in the cache. This is set high as one of my
    typical use cases is proxying distribution images.
 * `MEM_CACHE_SIZE`
    Default: `"128 MB"`
    Default memory cache size. I've no real clue what this should be, but RAM
    is plentiful so I like to keep it fairly large.
 * `CACHE_PEERx`
   Cache peers for the squid instance may be specified with multiple CACHE_PEER
   environment variables. The suffix of each is used to determine ordering by
   the unix `sort` function.
 * `EXTRA_CONFIGx`
   Extra non-specific configuration lines to be appended after the main body of
   the configuration file. This is a good place for custom ACL parameters.
 * `CONFIG_DISABLE`
   Default `no`
   If set to `yes` then squid configuration templating is disabled entirely, allowing
   bind mounting the configuration file in manually instead. The certificate and SSL
   setup still runs normally.
 * `DISABLE_CACHE`
   Default ``
   If set to `yes` then squid configuration templating removes all `cache_dir`
   lines, setting squid to memory only cache.
 * `TLS_OPTIONS`
   Default `NO_SSLv3,NO_TLSv1`
   Allow overriding the default tls_outgoing_options supplied to OpenSSL. These
   are safe defaults, but if you're in a really broken environment might not be
   usable.

# Proxychains
By default squid in SSL MITM mode treats `cache_peer` entries quite differently.
Because squid unwraps the CONNECT statement when bumping an SSL connection, but
does not rewrap it when communicating with peers, it requires all peers to connect
with SSL as well. This breaks compatibility with simple minded proxies.

To work around this, proxychains-ng (`proxychains4` internally) is built and
included in this image. If you need to use an upstream proxy with a MITM
squid4, you should launch the image in proxychains mode which intercepts squids
direct outbound connections and redirects them via CONNECT requests. This also
adds SOCKS4 and SOCKS5 proxy support if so desired.

proxychains is configured with the following environment variables. As with the
others above, `CONFIG_DISABLE` prevents overwriting templated files.

 * `PROXYCHAIN`
    Default none. If set to `yes` then squid will be launched with proxychains.
    You should specify some proxies when doing this.
 * `PROXYCHAIN_PROXYx`
    Upstream proxies to be passed to the proxy chan config file. The suffix (`x`)
    determines the order in which they are templated into the configuration file.
    The format is a space separated string like "http 127.0.0.1 3129"
 * `PROXYCHAIN_TYPE`
    Default `strict_chain`. Can be `strict_chain` or `dynamic_chain` sensibly
    within this image. In `strict_chain` mode, all proxies must be up. In
    `dynamic_chain` mode proxies are used in order, but skipped if down.
    Disable configuration and bind a configuration file to /etc/proxychains.conf
    if you need more flexibility.
 * `PROXYCHAIN_DNS`
   Default none. When set to `yes`, turns on the `proxy_dns` option for Proxychains.

# DNS-over-HTTPS
In some corporate environments, its not possible to get reliable DNS outbound
service and `proxychains-ng`'s DNS support won't be able to provide for Squid4
to actually work. To address this, configuration is included to setup and use
DNS-over-HTTPS.

The idea of the DNS-over-HTTPS client is that it will use your local proxy and
network access to provide DNS service to Squid4.

* `DNS_OVER_HTTPS`
  Default `no`. If `yes` then enables and starts the DNS_OVER_HTTPS service.
* `DNS_OVER_HTTPS_LISTEN_ADDR`
  Default `127.0.0.153:53`. Squid doesn't support changing the port, so keep
  this in mind.
* `DNS_OVER_HTTPS_SERVER`
  Default `https://dns.google.com/resolve`. AFAIK there's no other options for
  this at the moment.
* `DNS_OVER_HTTPS_NO_PROXY`
  Default ``. List of DNS suffixes to *not* ever proxy via DNS_OVER_HTTPS.
* `DNS_OVER_HTTPS_PREFIX_SERVER`
  Default ``. Normal DNS server to try resolving first against.
* `DNS_OVER_HTTPS_SUFFIX_SERVER`
  Default ``. Normal DNS server to try resolving last against.

Since the DNS-over-HTTPS daemon is a separate Go binary, you may also need to
specify your internal proxy as an upstream to allow it to contact the HTTPS
DNS server - do this by passing the standard `http_proxy` and `https_proxy`
parameters. Most likely these will be the same as your `PROXYCHAIN_PROXYx`
directives (and probably only the 1).

# Example Usage
The following command line will get you up and running quickly. It presumes
you've generated a suitable CA certificate and are intending to use the proxy
as a local MITM on your machine:
```
sudo mkdir -p /srv/squid/cache
docker run -it -p 3128:127.0.0.1:3128 --rm \
    -v /srv/squid/cache:/var/cache/squid4 \
    -v /etc/ssl/certs:/etc/ssl/certs:ro \
    -v /etc/ssl/private/local_mitm.pem:/local-mitm.pem:ro \
    -v /etc/ssl/certs/local_mitm.pem:/local-mitm.crt:ro \
    -e MITM_CERT=/local-mitm.crt \
    -e MITM_KEY=/local-mitm.pem \
    -e MITM_PROXY=yes \
    squid
```

Note that it doesn't really matter where we mount the certificate - the image
launch script makes a copy as root to avoid messing with permissions anyway.

## Unit File for systemd
This is an example of a systemd unit file to persistly start squid4:
```
[Unit]
Description=Squid4 Docker Container
Documentation=http://wiki.squid.org
After=network.target docker.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker kill squid4
ExecStartPre=-/usr/bin/docker rm squid4
ExecStart=/usr/bin/docker run --net=host --rm \
    -v /srv/squid/cache:/var/cache/squid4 \
    -v /etc/ssl/certs:/etc/ssl/certs:ro \
    -v /etc/ssl/private/local_mitm.pem:/local_mitm.pem:ro \
    -v /etc/ssl/certs/local_mitm.pem:/local_mitm.crt:ro \
    -e MITM_KEY=/local_mitm.pem \
    -e MITM_CERT=/local_mitm.crt \
    -e MITM_PROXY=yes \
    --name squid4 \
    squid

[Install]
WantedBy=multi-user.target
```
