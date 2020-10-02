provider "nomad" {
  address = "http://192.168.1.13:4646"
}

resource "nomad_job" "pihole" {
  jobspec = file("${path.module}/pihole.hcl")
}

resource "nomad_job" "cloudflared" {
  jobspec = file("${path.module}/cloudflared.hcl")
}

resource "nomad_job" "grafana" {
  jobspec = file("${path.module}/grafana.hcl")
}

resource "nomad_job" "traefik" {
  jobspec = file("${path.module}/traefik.hcl")
}

resource "nomad_job" "doods" {
  jobspec = file("${path.module}/doods.hcl")
}

resource "nomad_job" "atlantis" {
  jobspec = file("${path.module}/atlantis.hcl")
}

resource "nomad_job" "kapacitor" {
  jobspec = file("${path.module}/kapacitor.hcl")
}
