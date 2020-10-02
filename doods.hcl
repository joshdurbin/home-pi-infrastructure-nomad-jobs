job "doods" {

  datacenters = "pi"
  type        = "service"

  constraint {
    attribute = "${node.unique.name}"
    operator  = "="
    value     = "rpi-3bplus-1.node"
  }

  group "doods" {

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
        image = "snowzach/doods:latest"

        port_map {
          web = 8080
        }

        devices = [
          {
            host_path = "/dev/bus/usb"
            container_path = "/dev/bus/usb"
          }
        ]

        volumes = [
          "local/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite:/opt/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite",
          "local/coco_labels.txt:/opt/coco_labels.txt",
          "local/config.yaml:/opt/doods/config.yaml"
        ]
      }

      artifact {
        source = "https://github.com/google-coral/test_data/raw/master/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite"
      }

      artifact {
        source = "https://github.com/google-coral/test_data/raw/master/coco_labels.txt"
      }

      template {
        data = <<EOH
doods:
  logger:
    level: error
  detectors:
    - name: default
      type: tflite
      modelFile: /opt/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite
      labelFile: /opt/coco_labels.txt
      numThreads: 4
      numConcurrent: 4
      hwAccel: true
EOH
        destination   = "local/config.yaml"
        change_mode   = "restart"
      }

      resources {
        cpu    = 1000
        memory = 256
        network {
          port "web" {

          }
        }
      }

      service {
        name = "doods"
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

