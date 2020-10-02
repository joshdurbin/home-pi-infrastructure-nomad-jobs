job "elasticsearch" {
  type = "service"
  datacenters = [
    "pi"]

  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "180s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
  }

  meta {
    ES_CLUSTER_NAME = "ESLOCAL-${NOMAD_JOB_NAME}"
  }


  group "es-cluster-master" {
    count = 1



    task "es-cluster-master" {
      driver = "docker"

      user = "root"

      kill_timeout = "600s"

      kill_signal = "SIGTERM"

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:7.6.2"
        command = "elasticsearch"

        # https:#www.elastic.co/guide/en/elasticsearch/reference/current/modules-transport.html
        # https:#www.elastic.co/guide/en/elasticsearch/reference/current/modules-http.html
        args = [
          "-Ebootstrap.memory_lock=true",
          # lock all JVM memory on startup
          # "-Ecloud.node.auto_attributes=true",                     # use AWS API to add additional meta data to the client (like AZ)
          "-Ecluster.name=${NOMAD_META_ES_CLUSTER_NAME}",
          # name of the cluster - this must match between master and data nodes
          "-Ediscovery.zen.hosts_provider=file",
          # use a 'static' file
          "-Ediscovery.zen.minimum_master_nodes=1",
          # >= 2 master nodes are required to form a healthy cluster
          "-Egateway.expected_data_nodes=1",
          # >= 3 data nodes to form a healthy cluster
          "-Egateway.expected_master_nodes=1",
          # >= 3 master nodes are the expected state of the cluster
          "-Egateway.expected_nodes=1",
          # >= 3 nodes in total are expected to be in the cluster
          "-Egateway.recover_after_nodes=1",
          # >= 3 nodes are required to start data recovery
          "-Ehttp.port=${NOMAD_PORT_rest}",
          # HTTP port (originally port 9200) to listen on inside the container
          "-Ehttp.publish_port=${NOMAD_HOST_PORT_rest}",
          # HTTP port (originally port 9200) on the host instance
          "-Enetwork.host=site",
          # IP to listen on for all traffic
          #"-Enetwork.publish_host=${NOMAD_IP_rest}",               # IP to broadcast to other elastic search nodes (this is a host IP, not container)
          #"-Enetwork.publish_host=${NOMAD_JOB_NAME}-elastic",               # IP to broadcast to other elastic search nodes (this is a host IP, not container)
          "-Enetwork.publish_host=site",
          # IP to broadcast to other elastic search nodes (this is a host IP, not container)
          "-Enode.data=true",
          # node is allowed to store data
          "-Enode.master=true",
          # node is allowed to be elected master
          "-Enode.name=${NOMAD_GROUP_NAME}[${NOMAD_ALLOC_INDEX}]",
          # node name is defauled to the allocation name
          "-Epath.logs=/alloc/logs/",
          # log data to allocation directory
          "-Etransport.publish_port=${NOMAD_HOST_PORT_transport}",
          # Transport port (originally port 9300) on the host instance
          "-Etransport.tcp.port=${NOMAD_PORT_transport}",
          # Transport port (originally port 9300) inside the container

          "-Expack.license.self_generated.type=basic",
          # use x-packs basic license (free)
          "-Ecluster.initial_master_nodes=${NOMAD_GROUP_NAME}[${NOMAD_ALLOC_INDEX}]"
        ]

        ulimit {
          memlock = "-1"
          nofile = "65536"
          nproc = "8192"
        }

        mounts = [
          # sample volume mount
          {
            type = "bind"
            target = "/usr/share/elasticsearch/data"
            #"/path/in/container"
            source = "/opt/elastic/vol_elastic/data"
            #"/path/in/host"
            readonly = false
            bind_options
            {
            propagation = "rshared"
            }
          }
        ]

      }


      # this consul service is used to discover unicast hosts (see above template{})
      service {
        name = "${NOMAD_JOB_NAME}-discovery"
        port = "transport"


        check {
          name = "transport-tcp"
          port = "transport"
          type = "tcp"
          interval = "5s"
          timeout = "4s"
        }

      }

      # this consul service is used for port 9200 / normal http traffic
      service {
        name = "${NOMAD_JOB_NAME}-elastic"
        port = "rest"
        tags = [
          "dd-elastic"]

        check {
          name = "rest-tcp"
          port = "rest"
          type = "tcp"
          interval = "5s"
          timeout = "4s"
        }

        check {
          name = "rest-http"
          type = "http"
          port = "rest"
          path = "/"
          interval = "5s"
          timeout = "4s"
        }
      }

      resources {
        cpu = 1000
        memory = 4096
        #mbits = 25
        network {
          mode = "bridge"
          port "rest" {
            static = 9200
            to = 9200
          }
          port "transport" {
            static = 9300
            to = 9300
          }
          port "http" {}
        }
      }
    }
  }
}