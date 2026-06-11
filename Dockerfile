FROM debian:bullseye AS builder

RUN apt-get update -y && \
    apt-get install -y wget gnupg ca-certificates && \
    echo "deb [trusted=yes] https://download.ceph.com/debian-16.2.15/ bullseye main" > /etc/apt/sources.list.d/ceph.list && \
    apt-get update -y && \
    apt-get install -y build-essential librados-dev librbd-dev

COPY . /src
WORKDIR /src
RUN make programs CEPH_RBD=1


FROM debian:bullseye

RUN apt-get update -y && \
    apt-get install -y wget gnupg ca-certificates && \
    echo "deb [trusted=yes] https://download.ceph.com/debian-16.2.15/ bullseye main" > /etc/apt/sources.list.d/ceph.list && \
    apt-get update -y && \
    apt-get install -y librbd1 librados2 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/usr/tgtd /src/usr/tgtadm /src/usr/tgtimg /usr/sbin/
COPY --from=builder /src/usr/bs_rbd.so /usr/lib/tgt/backing-store/
