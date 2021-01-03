job "grafana" {
  datacenters = "pi"
  type        = "service"

  constraint {
    attribute = "${meta.machine_type}"
    operator  = "="
    value     = "pi4b"
  }

  group "grafana" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:7.3.4"

        port_map {
          grafana_port = 3000
        }
      }

      resources {
        cpu    = 128
        memory = 128
        network {
          port "grafana_port" {

          }
        }
      }

      service {
        name = "grafana"
        port = "grafana_port"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.grafana.rule=Host(`grafana.traefik`)"
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
