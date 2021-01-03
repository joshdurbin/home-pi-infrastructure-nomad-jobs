job "loki" {
  datacenters = "pi"
  type        = "service"

  constraint {
    attribute = "${node.unique.name}"
    operator  = "="
    value     = "rpi-4b-3.node"
  }

  group "loki" {
    count = 1

    volume "loki" {
      type      = "host"
      read_only = false
      source    = "loki"
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "loki" {
      driver = "docker"

      volume_mount {
        volume      = "loki"
        destination = "/data/loki/"
        read_only   = false
      }

      config {

        image = "grafana/loki"

        port_map {
          loki_port = 3100
        }

        volumes = [
          "local/config.yaml:/etc/loki/local-config.yaml"
        ]
      }

      template {
        data = <<EOH
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h       # Any chunk not receiving new logs in this time will be flushed
  max_chunk_age: 1h           # All chunks will be flushed when they hit this age, default is 1h
  chunk_target_size: 1048576  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_retain_period: 30s    # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  max_transfer_retries: 0     # Chunk transfers disabled

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /data/loki/boltdb-shipper-active
    cache_location: /data/loki/boltdb-shipper-cache
    cache_ttl: 24h         # Can be increased for faster performance over longer query periods, uses more disk space
    shared_store: filesystem
  filesystem:
    directory: /data/loki/chunks

compactor:
  working_directory: /data/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /data/loki/rules
  rule_path: /data/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
EOH
        destination   = "local/config.yaml"
        change_mode   = "restart"
      }

      resources {
        cpu    = 512
        memory = 256

        network {
          mbits = 250
          port  "loki_port"{}
        }
      }

      service {
        name = "loki"
        port = "loki_port"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.loki.rule=Host(`loki.traefik`)"
        ]

        check {
          type     = "http"
          path     = "/ready"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}