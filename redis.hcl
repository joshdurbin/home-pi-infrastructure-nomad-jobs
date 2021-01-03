job "redis" {

  datacenters = "pi"
  type        = "service"

  constraint {
    attribute = "${meta.machine_type}"
    operator  = "="
    value     = "pi4b"
  }

  group "redis" {

    count = 1

    task "redis" {
      driver = "docker"

      config {
        image = "redis:latest"

//        cpu_hard_limit = true

        port_map {
          redis = 6379
        }

        logging {
          type = "fluentd"
          config {
            fluentd-address = "${attr.unique.network.ip-address}:24224"
          }
        }
      }

      resources {
        cpu    = 256
        memory = 512
        network {
          port "redis" {}
        }
      }

      service {
        name = "redis"
        port = "redis"

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

