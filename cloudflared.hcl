job "cloudflard" {

  datacenters = "pi"
  type        = "service"

  constraint {
    attribute = "${meta.machine_type}"
    operator  = "="
    value     = "pi4b"
  }

  group "cloudflard" {

    count = 1

    task "cloudflared" {
      driver = "docker"

      config {
        image = "visibilityspots/cloudflared"

        port_map {
          dns = 5054
        }
      }

      resources {
        cpu    = 256
        memory = 128
        network {
          port "dns" {}
        }
      }

      service {
        name = "cloudflared"
        port = "dns"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

