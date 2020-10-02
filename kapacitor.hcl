job "kapacitor" {

  datacenters = "pi"
  type        = "service"

  group "kapacitor" {

    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "kapacitor" {
      driver = "docker"

      config {
        image = "kapacitor:latest"

        port_map {
          web = 8080

        }

        volumes = [
          "local/kapacitor.conf:/etc/kapacitor/kapacitor.conf"
        ]
      }

      template {
        data = <<EOH
# The hostname of this node.
# Must be resolvable by any configured InfluxDB hosts.
hostname = "localhost"
# Directory for storing a small amount of metadata about the server.
data_dir = "/var/lib/kapacitor"

# Do not apply configuration overrides during startup.
# Useful if the configuration overrides cause Kapacitor to fail startup.
# This option is intended as a safe guard and should not be needed in practice.
skip-config-overrides = false

# Default retention-policy, if a write is made to Kapacitor and
# it does not have a retention policy associated with it,
# then the retention policy will be set to this value
default-retention-policy = ""

[[udp]]
    enabled = true
    bind-address = ":9100"
    database = "default"
    retention-policy = "autogen"

[http]
  # HTTP API Server for Kapacitor
  # This server is always on,
  # it serves both as a write endpoint
  # and as the API endpoint for all other
  # Kapacitor calls.
  bind-address = ":9092"
  log-enabled = true
  write-tracing = false
  pprof-enabled = false
  https-enabled = false
  https-certificate = "/etc/ssl/kapacitor.pem"
  ### Use a separate private key location.
  # https-private-key = ""


[config-override]
  # Enable/Disable the service for overridding configuration via the HTTP API.
  enabled = true

[logging]
    file = "/var/log/kapacitor/kapacitor.log"
    level = "INFO"

[load]
  enabled = true
  dir = "/etc/kapacitor/load"

[replay]
  dir = "/var/lib/kapacitor/replay"

[task]
  dir = "/var/lib/kapacitor/tasks"
  snapshot-interval = "60s"

[storage]
  boltdb = "/var/lib/kapacitor/kapacitor.db"

[deadman]
  global = false

[[influxdb]]
  enabled = false

[kubernetes]
  enabled = false

[smtp]
  enabled = false

[snmptrap]
  enabled = false

[opsgenie]
  enabled = false

[opsgenie2]
  enabled = false

[victorops]
  enabled = false

[pagerduty]
  enabled = false

[pagerduty2]
  enabled = false

[pushover]
  enabled = false

[[slack]]
  enabled = false

[telegram]
  enabled = false

[hipchat]
  enabled = false

[[kafka]]
  enabled = false

[alerta]
  enabled = false

[servicenow]
  enabled = false

[sensu]
  enabled = false

[reporting]
  enabled = false

[stats]
  enabled = true
  stats-interval = "10s"
  database = "_kapacitor"
  retention-policy= "autogen"

[udf]
# Configuration for UDFs (User Defined Functions)
[udf.functions]
    # Example go UDF.
    # First compile example:
    #   go build -o avg_udf ./udf/agent/examples/moving_avg.go
    #
    # Use in TICKscript like:
    #   stream.goavg()
    #           .field('value')
    #           .size(10)
    #           .as('m_average')
    #
    # uncomment to enable
    #[udf.functions.goavg]
    #   prog = "./avg_udf"
    #   args = []
    #   timeout = "10s"

    # Example python UDF.
    # Use in TICKscript like:
    #   stream.pyavg()
    #           .field('value')
    #           .size(10)
    #           .as('m_average')
    #
    # uncomment to enable
    #[udf.functions.pyavg]
    #   prog = "/usr/bin/python2"
    #   args = ["-u", "./udf/agent/examples/moving_avg.py"]
    #   timeout = "10s"
    #   [udf.functions.pyavg.env]
    #       PYTHONPATH = "./udf/agent/py"

    # Example UDF over a socket
    #[udf.functions.myCustomUDF]
    #   socket = "/path/to/socket"
    #   timeout = "10s"

[talk]
  enabled = false

[[mqtt]]
  enabled = false

[[swarm]]
  enabled = false

[collectd]
  enabled = false

[opentsdb]
  enabled = false

[[scraper]]
  enabled = false

[[azure]]
  enabled = false

[[consul]]
  enabled = false
  id = "myconsul"
  address = "127.0.0.1:8500"
  token = ""
  datacenter = ""
  tag-separator = ","
  scheme = "http"
  username = ""
  password = ""
  ssl-ca = ""
  ssl-cert = ""
  ssl-key = ""
  ssl-server-name = ""
  insecure-skip-verify = false

[[dns]]
  enabled = false

[[ec2]]
  enabled = false

[[file-discovery]]
  enabled = false

[[gce]]
  enabled = false

[[marathon]]
  enabled = false

[[nerve]]
  enabled = false

[[serverset]]
  enabled = false

[[static-discovery]]
  enabled = false

[[triton]]
  enabled = false

EOH
        destination   = "local/kapacitor.conf"
        change_mode   = "restart"
      }

      resources {
        cpu    = 128
        memory = 128
        network {
          port "web" {

          }
        }
      }

      service {
        name = "kapacitor"
        port = "web"

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

