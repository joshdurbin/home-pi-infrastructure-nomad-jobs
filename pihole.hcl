job "pihole" {

  datacenters = "pi"
  type        = "service"

  group "pihole" {

    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "pihole" {
      driver = "docker"

      config {
        image = "pihole/pihole:latest"

        port_map {
          dns = 53
          web = 80
        }
      }

      env = {
        "WEBPASSWORD"  = "noads"
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          port "dns" {

          }
          port "web" {

          }
        }
      }

      template {

        destination = "/etc/cloudflared.service"
        change_mode = "restart"
        env         = "true"
        data        = <<EOH
DNS1="{{range service "cloudflared"}}{{.Address}}#{{.Port}}{{end}}"
EOH

      }

      service {
        name = "pihole"
        port = "web"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pihole.rule=Host(`pihole.traefik`)"
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "pihole-dns"
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

