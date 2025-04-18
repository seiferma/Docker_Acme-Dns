variable "VERSION" {
  # renovate: datasource=github-tags depName=joohoi/acme-dns
  default = "v1.1"
}

target "default" {
  platforms = ["linux/amd64", "linux/arm64"]
  tags = [
    "quay.io/seiferma/acme-dns:${VERSION}",
    "quay.io/seiferma/acme-dns:latest"
  ]
  args = {
    VERSION = "${VERSION}"
  }
}
