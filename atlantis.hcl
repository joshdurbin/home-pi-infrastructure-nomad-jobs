job "atlantis" {

  datacenters = "pi"
  type        = "service"

  group "atlantis" {

    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "doods" {
      driver = "docker"

      config {
        image = "runatlantis/atlantis"

        port_map {
          web = 4141
        }

      }

      resources {
        cpu    = 100
        memory = 128
        network {
          port "web" {

          }
        }
      }

      service {
        name = "atlantis"
        port = "web"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.atlantis.rule=Host(`atlantis.traefik`)"
        ]

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

