FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

ENV SOFTETHER_VER=5.02.5180 \
        SHA256_SUM=b5649a8ea3cc6477325e09e2248ef708d434ee3b2251eb8764bcfc15fb1de456

SHELL ["/bin/bash", "-c"]

# Install build tools
RUN apt-get update && apt-get install -y \
        cmake \
        gcc \
        g++ \
        make \
        libncurses5-dev \
        libssl-dev \
        libssl3 \
        libsodium-dev \
        libreadline-dev \
        zlib1g-dev \
        pkg-config \
        wget

RUN wget --no-check-certificate https://github.com/SoftEtherVPN/SoftEtherVPN/releases/download/${SOFTETHER_VER}/SoftEtherVPN-${SOFTETHER_VER}.tar.xz \
        && echo "${SHA256_SUM}  SoftEtherVPN-${SOFTETHER_VER}.tar.xz" | sha256sum -c \
        && mkdir -p /usr/local/src \
        && tar -x -C /usr/local/src/ -f SoftEtherVPN-${SOFTETHER_VER}.tar.xz \
        && mv /usr/local/src/SoftEtherVPN-${SOFTETHER_VER} /usr/local/src/SoftEtherVPN \
        && rm SoftEtherVPN-${SOFTETHER_VER}.tar.xz

RUN cd /usr/local/src/SoftEtherVPN && \
        ./configure && \
        make -C build

FROM ubuntu:22.04

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
        libncurses5 \
        libsodium23 \
        libreadline8 \
        libssl3 \
        iptables \
        zlib1g \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/bin

COPY --from=builder \
        /usr/local/src/SoftEtherVPN/build/vpnserver \
        /usr/local/src/SoftEtherVPN/build/vpncmd \
        /usr/local/src/SoftEtherVPN/build/libcedar.so \
        /usr/local/src/SoftEtherVPN/build/libmayaqua.so \
        /usr/local/src/SoftEtherVPN/build/hamcore.se2 \
        ./

VOLUME /mnt

RUN mkdir -p /mnt/backup.vpn_server.config && \
        ln -s /mnt/vpn_server.config vpn_server.config && \
        ln -s /mnt/backup.vpn_server.config backup.vpn_server.config && \
        ln -s /mnt/lang.config lang.config

EXPOSE 443/tcp 992/tcp 1194/tcp 1194/udp 5555/tcp 500/udp 4500/udp

CMD ["/usr/local/bin/vpnserver", "execsvc"]
