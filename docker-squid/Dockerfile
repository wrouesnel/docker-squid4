ARG DOCKER_PREFIX=

FROM ${DOCKER_PREFIX}ubuntu:18.04

ARG TRUST_CERT=

RUN if [ ! -z "$TRUST_CERT" ]; then \
        echo "$TRUST_CERT" > /usr/local/share/ca-certificates/build-trust.crt ; \
        update-ca-certificates ; \
    fi

# load normalized apt sources
COPY sources.list /etc/apt/sources.list

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      apt-utils \
      curl \
      dnsutils \
      emacs25-nox \
      git \
      haproxy \
      libssl-dev \
      screen \
      squid \
      tar \
      tig \
      tmux \
      ubuntu-server \
      vim.tiny \
      wget \
      xz-utils \
      && \
    DEBIAN_FRONTEND=noninteractive apt-get build-dep -y squid3

#ARG SQUID_VERSION=4.6
#ARG SQUID_SHA512=dbe2b02b83d53d67459e22a19e71cbf99b66d74a2ddc4bc69310f03a0a6092e5840766ad699fc43893516e97ef89799ef2147dd40f76b0bd688c1e271fd20d06
## TODO: verify this hash independently
#
#RUN mkdir /src \
#    && cd /src \
#    && wget http://www.squid-cache.org/Versions/v4/squid-$SQUID_VERSION.tar.xz \
#    && ( sha512sum squid-$SQUID_VERSION.tar.xz | grep -q $SQUID_SHA512 ) \
#    && mkdir squid \
#    && tar -C squid --strip-components=1 -xvf squid-$SQUID_VERSION.tar.xz

ARG SQUID_SHA512=562fcb458591a04d5e724ff05fd21b076706fb1a8bd7085f89ae9c4a8fa78c764d65479e698e3821182efb6b9cebb1e3e3147d532471612b1d6b3280e18a72b9

# (cloned from https://github.com/measurement-factory/squid into https://github.com/wireapp/squid)
RUN mkdir /src \
    && cd /src \
    && git clone -b SQUID-412-initial-proxy-protocol-support-on-https-port https://github.com/wireapp/squid \
    && cd ./squid \
    && git checkout 0456747085cbd19f4c01fc1c4e4625c1c32de205 \
    && git grep -l '.' | xargs sha512sum | sort | sha512sum | grep -q $SQUID_SHA512

ARG CONCURRENCY=5

RUN cd /src/squid && \
    ./bootstrap.sh && \
    ./configure \
        --prefix=/usr \
        --datadir=/usr/share/squid4 \
                --sysconfdir=/etc/squid4 \
                --localstatedir=/var \
                --mandir=/usr/share/man \
                --enable-inline \
                --enable-async-io=8 \
                --enable-storeio="ufs,aufs,diskd,rock" \
                --enable-removal-policies="lru,heap" \
                --enable-delay-pools \
                --enable-cache-digests \
                --enable-underscores \
                --enable-icap-client \
                --enable-follow-x-forwarded-for \
                --enable-auth-basic="DB,fake,getpwnam,LDAP,NCSA,NIS,PAM,POP3,RADIUS,SASL,SMB" \
                --enable-auth-digest="file,LDAP" \
                --enable-auth-negotiate="kerberos,wrapper" \
                --enable-auth-ntlm="fake" \
                --enable-external-acl-helpers="file_userip,kerberos_ldap_group,LDAP_group,session,SQL_session,unix_group,wbinfo_group" \
                --enable-url-rewrite-helpers="fake" \
                --enable-eui \
                --enable-esi \
                --enable-icmp \
                --enable-zph-qos \
                --with-openssl \
                --enable-ssl \
                --enable-ssl-crtd \
                --disable-translation \
                --with-swapdir=/var/spool/squid4 \
                --with-logdir=/var/log/squid4 \
                --with-pidfile=/var/run/squid4.pid \
                --with-filedescriptors=65536 \
                --with-large-files \
                --with-default-user=proxy \
                --disable-arch-native \
                --disable-ipv6 \
                --enable-linux-netfilter \
                --enable-ipfw-transparent \
                --enable-pf-transparent \
                && \
    make -j$CONCURRENCY && \
    make install

# (in the squid build commands above, `--enable-ipf-transparent` would yield a ./configure error.)

# everything we share between host and container is here:
RUN mkdir -p ./mnt/

# Configuration environment
ENV MITM_PROXY= \
    MITM_CERT= \
    MITM_KEY=

EXPOSE 3128
EXPOSE 3129

ENTRYPOINT [ "/mnt/entrypoint.sh" ]
