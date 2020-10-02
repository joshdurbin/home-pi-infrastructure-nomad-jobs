job "traefik" {
  region      = "global"
  datacenters = ["pi"]
  type        = "service"

  spread {
    attribute = "${node.unique.name}"
  }

  constraint {
    attribute = "${meta.machine_type}"
    operator  = "="
    value     = "pi4b"
  }

  group "traefik" {
    count = 2

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.3.1"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[global]
  checkNewVersion = false
  sendAnonymousUsage = false

[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.http.forwardedHeaders]
        insecure = true
    [entryPoints.traefik]
    address = ":8081"

[log]
  level = "DEBUG"

[accessLog]
  format = "json"

[api]
    dashboard = true
    insecure  = true
    debug = true

[metrics]
    [metrics.prometheus]
        buckets = [0.1,0.3,0.5,1.0,1.5,5.0]
        entryPoint = "traefik"

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false

    [providers.consulCatalog.endpoint]
      address = "127.0.0.1:8500"
      scheme  = "http"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128

        network {

          port "http" {
            static = 80
          }

          port "api" {
            static = 8081
          }
        }
      }

      service {
        name = "traefik"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

