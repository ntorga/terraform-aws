#
## K8s Metrics Server Chart
#
resource "helm_release" "metrics-server" {
  name       = "my-release"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  version    = "5.8.9"

  set {
    name  = "apiService.create"
    value = "true"
  }
}
