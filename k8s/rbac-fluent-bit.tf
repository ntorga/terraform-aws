#
## Fluent Bit RBAC
#
resource "kubernetes_service_account" "fluent-bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "logging"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "fluent-bit-read" {
  metadata {
    name = "fluent-bit-read"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluent-bit-read" {
  metadata {
    name = "fluent-bit-read"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "fluent-bit-read"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fluent-bit"
    namespace = "logging"
  }
}
