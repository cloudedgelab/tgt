FROM debian:bookworm-slim AS builder
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        librados-dev \
        librbd-dev

COPY . /src
WORKDIR /src
RUN make programs CEPH_RBD=1

FROM debian:bookworm-slim

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        librbd1 \
        librados2 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/usr/tgtd /src/usr/tgtadm /src/usr/tgtimg /usr/sbin/
COPY --from=builder /src/usr/bs_rbd.so /usr/lib/tgt/backing-store/
