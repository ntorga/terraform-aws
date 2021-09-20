#
## Fluent Bit DaemonSet
#
resource "kubernetes_daemonset" "fluent-bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "logging"
    labels = {
      "k8s-app"                       = "fluent-bit-logging"
      "version"                       = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluent-bit-logging"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app"                       = "fluent-bit-logging"
          "version"                       = "v1"
          "kubernetes.io/cluster-service" = "true"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "2020"
          "prometheus.io/path"   = "/api/v1/metrics/prometheus"
        }
      }

      spec {
        automount_service_account_token = true
        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
        volume {
          name = "fluent-bit-config"
          config_map {
            name = "fluent-bit-config"
          }
        }
        container {
          image             = "fluent/fluent-bit:1.7"
          name              = "fluent-bit"
          image_pull_policy = "Always"
          resources {
            limits {
              cpu    = var.stage-container-limits.micro.cpu
              memory = var.stage-container-limits.micro.memory
            }
          }
          port {
            container_port = 2020
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_HOST"
            value = var.elasticsearch-host
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_PORT"
            value = 443
          }
          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
          }
        }
        termination_grace_period_seconds = 10
        service_account_name             = "fluent-bit"
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}
