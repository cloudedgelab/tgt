FROM debian:bookworm AS builder

RUN echo "deb http://ftp.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
    rm -f /etc/apt/sources.list.d/debian.sources  && \
    apt-get update -y && \
    apt-get install -y wget gnupg ca-certificates && \
    apt-get update -y && \
    apt-get install -y build-essential librados-dev librbd-dev

COPY . /src
WORKDIR /src
RUN make programs CEPH_RBD=1
RUN ldd /src/usr/bs_rbd.so

FROM debian:bookworm

RUN echo "deb http://ftp.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
    rm -f /etc/apt/sources.list.d/debian.sources  && \
    apt-get update -y && \
    apt-get install -y wget gnupg ca-certificates && \
    apt-get update -y && \
    apt-get install -y librbd1 librados2 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/usr/tgtd /src/usr/tgtadm /src/usr/tgtimg /usr/sbin/
COPY --from=builder /src/usr/bs_rbd.so /usr/lib/tgt/backing-store/
RUN ldd /usr/lib/tgt/backing-store/bs_rbd.so && ldd /usr/sbin/tgtd
