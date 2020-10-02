job "cloudflard" {

  datacenters = "pi"
  type        = "service"

  affinity {
    attribute = "${node.unique.name}"
    value     = "rpi-4b-2.node"
    weight    = 100
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
        cpu    = 100
        memory = 100
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

