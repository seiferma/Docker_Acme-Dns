FROM --platform=$BUILDPLATFORM alpine:latest@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS downloader
ARG VERSION=latest

RUN apk add --no-cache curl jq
RUN curl -L -s -o /tmp/acme-dns.tar.gz "https://github.com/joohoi/acme-dns/archive/refs/tags/$VERSION.tar.gz" && \
    mkdir /tmp/acme-dns && \
    tar -xzf /tmp/acme-dns.tar.gz --strip-components=1 -C /tmp/acme-dns



FROM --platform=$BUILDPLATFORM tonistiigi/xx@sha256:923441d7c25f1e2eb5789f82d987693c47b8ed987c4ab3b075d6ed2b5d6779a3 AS xx
FROM golang:1.22-alpine@sha256:1699c10032ca2582ec89a24a1312d986a3f094aed3d5c1147b19880afe40e052 AS builder-platform

FROM --platform=$BUILDPLATFORM golang:1.22-alpine@sha256:1699c10032ca2582ec89a24a1312d986a3f094aed3d5c1147b19880afe40e052 AS builder
RUN apk add clang lld
COPY --from=xx / /
ARG TARGETPLATFORM
RUN xx-apk add musl-dev gcc
ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
COPY --from=downloader /tmp/acme-dns /tmp/acme-dns
WORKDIR /tmp/acme-dns
RUN xx-go build
RUN xx-verify acme-dns
RUN mkdir /tmp/empty



FROM scratch

WORKDIR /opt/acme-dns
ENTRYPOINT ["./acme-dns"]
EXPOSE 53 53/udp 80 443

COPY --from=builder /tmp/empty /etc/acme-dns
COPY --from=builder /tmp/empty /var/lib/acme-dns
COPY --from=builder-platform /lib/ld-musl-*.so.* /lib/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /tmp/acme-dns/acme-dns .
