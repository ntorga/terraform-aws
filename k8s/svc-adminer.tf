#
## adminer Deployment & Service
#
resource "kubernetes_deployment" "adminer" {
  metadata {
    name      = "adminer"
    namespace = "devops"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "adminer"
      }
    }
    template {
      metadata {
        labels = {
          app = "adminer"
        }
        # Access logs are ignored cause we get those logs from the Ing. Controller.
        annotations = {
          "fluentbit.io/parser_stderr"  = "nginx_error"
          "fluentbit.io/exclude_stdout" = true
        }
      }
      spec {
        container {
          image = "adminer:latest"
          name  = "adminer"
          port {
            container_port = 8080
          }
          resources {
            limits = {
              cpu    = var.stage-container-limits.micro.cpu
              memory = var.stage-container-limits.micro.memory
            }
          }
          env {
            name  = "ADMINER_DEFAULT_SERVER"
            value = "REPLACE-THIS-WITH-RDS-HOST"
          }
          env {
            name  = "ADMINER_DESIGN"
            value = "pepa-linha"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "adminer" {
  metadata {
    name      = "adminer"
    namespace = "devops"
  }
  spec {
    selector = {
      app = "adminer"
    }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}
