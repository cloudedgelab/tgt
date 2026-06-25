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

WORKDIR /custom-libs
RUN wget -q -O librados.so.2.0.0 "https://files.sysop.tingyutech.net/api/public/dl/6VHnFtMh?token=fj2eLh5VSCb2GFeiD6RK9hFOsf2hUzZQ0BgZtJF3glszffuHlv-tp69kjqZS64OLxrI4tynQI1P4p_8nO56F6n5b5z-8sT4V_bApdVgR4QJGJF5G0Oprqc2MCs4JXASo" && \
    wget -q -O librbd.so.1.16.0 "https://files.sysop.tingyutech.net/api/public/dl/6UW50_bP?token=kczECaW1G55C9r4IrYP_oiHna4grsZU0O1CljvjE1u4IySeUuCfmdyPf1vIOJYx2t3N0uvs9HdepRP-t1apFTXczVnvgfdgTcJsZjNCVH8-oq4jCXX-z4kWhkl-Qwruq" && \
    wget -q -O libceph-common.so.2 "https://files.sysop.tingyutech.net/api/public/dl/v_wk81L5?token=FvP5d7Tq5k8kDrB6OF8hloUqTmLVg43_VvIMuha-KpGuy4bkNRh9rw5lB8hZ0a07uTppeaw2A2afve3nJCbBW9a8nhwwlRGIdShmwQCwt7ETyUNZc2MdxEIO2Uq9n8ra"

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

COPY --from=builder /custom-libs/librados.so.2.0.0 /usr/local/lib/
COPY --from=builder /custom-libs/librbd.so.1.16.0 /usr/local/lib/
COPY --from=builder /custom-libs/libceph-common.so.2 /usr/local/lib/ceph/

RUN chmod 644 /usr/local/lib/librados.so.2.0.0 /usr/local/lib/librbd.so.1.16.0 /usr/local/lib/ceph/libceph-common.so.2

RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/00-custom-ceph.conf && \
    echo "/usr/local/lib/ceph" >> /etc/ld.so.conf.d/00-custom-ceph.conf && \
    ldconfig

RUN ldd /usr/lib/tgt/backing-store/bs_rbd.so && ldd /usr/sbin/tgtd
