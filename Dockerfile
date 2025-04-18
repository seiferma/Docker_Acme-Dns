FROM --platform=$BUILDPLATFORM alpine:latest AS downloader
ARG VERSION=latest

RUN apk add --no-cache curl jq
RUN curl -L -s -o /tmp/acme-dns.tar.gz "https://github.com/joohoi/acme-dns/archive/refs/tags/$VERSION.tar.gz" && \
    mkdir /tmp/acme-dns && \
    tar -xzf /tmp/acme-dns.tar.gz --strip-components=1 -C /tmp/acme-dns



FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM golang:1.24-alpine AS builder-platform

FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder
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
