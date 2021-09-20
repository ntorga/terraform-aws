#
## Kibana Ingress
#
resource "kubernetes_ingress" "kibana-proxy" {

  metadata {
    name      = "kibana-proxy"
    namespace = "devops"
    annotations = {
      "kubernetes.io/ingress.class"                  = "nginx"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
      "nginx.ingress.kubernetes.io/auth-type"        = "basic"
      "nginx.ingress.kubernetes.io/auth-secret"      = "devops/kibana-auth"
      "nginx.ingress.kubernetes.io/auth-realm"       = "Authentication Required"
    }
  }

  spec {
    rule {
      host = "kibana.${var.stage-domain}"

      http {
        path {
          path = "/"
          backend {
            service_name = "kibana-proxy"
            service_port = 80
          }
        }
      }
    }
  }
}
