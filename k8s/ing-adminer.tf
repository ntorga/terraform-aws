#
## adminer Secret
#
data "aws_secretsmanager_secret_version" "devops-adminer-creds" {
  secret_id = "devops-adminer-creds"
}

locals {
  devops-adminer-creds = jsondecode(
    data.aws_secretsmanager_secret_version.devops-adminer-creds.secret_string
  )
}

resource "kubernetes_secret" "adminer-auth" {
  metadata {
    name      = "adminer-auth"
    namespace = "devops"
  }

  data = {
    "auth" = "${local.devops-adminer-creds.username}:${local.devops-adminer-creds.bcrypted-password}"
  }
}

#
## adminer Ingress
#
resource "kubernetes_ingress" "adminer" {

  metadata {
    name      = "adminer"
    namespace = "devops"
    annotations = {
      "kubernetes.io/ingress.class"                  = "nginx"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
      "nginx.ingress.kubernetes.io/auth-type"        = "basic"
      "nginx.ingress.kubernetes.io/auth-secret"      = "devops/adminer-auth"
      "nginx.ingress.kubernetes.io/auth-realm"       = "Authentication Required"
    }
  }

  spec {
    rule {
      host = "adminer.${var.stage-domain}"

      http {
        path {
          path = "/"
          backend {
            service_name = "adminer"
            service_port = 8080
          }
        }
      }
    }
  }
}
