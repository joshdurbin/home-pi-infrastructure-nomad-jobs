job "fluent-bit" {
  datacenters = "pi"
  type = "system"
  group "fluent-bit" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "fluent-bit" {
      driver = "docker"
      config {
        image = "bitholla/fluent-bit-plugin-loki:4da505b"
        ports = [
          "fluentd"]
        volumes = [
          "local/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf",
        ]
      }

      resources {
        cpu = 128
        memory = 128
        network {
          mode = "host"
          port "fluentd" {
            static = 24224
          }
        }
      }

      template {
        data = <<EOH
[INPUT]
    Name        forward
    Listen      0.0.0.0
    Port        24224
[Output]
    Name loki
    Match *
    Url {{range service "loki"}}http://{{.Address}}:{{.Port}}/loki/api/v1/push{{end}}
    RemoveKeys source,container_id
    Labels {job="fluent-bit", hostname="{{env "attr.unique.hostname" }}"}
    LabelKeys container_name
    BatchWait 1
    BatchSize 1001024
    LineFormat json
    LogLevel info
EOH
        destination = "local/fluent-bit.conf"
        change_mode = "restart"
      }
    }
  }
}