target "default" {
  name = "${regex_replace("app-${version}", "[.#]", "_")}"
  matrix = {
    version = ["latest", "v1.0"]
  }
  platforms = ["linux/amd64", "linux/arm64"]
  tags = ["quay.io/seiferma/acme-dns:${version}"]
  args = {
    VERSION = "${version}"
  }
}
