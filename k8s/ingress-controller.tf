#
## NGINX Ingress Controller Chart
#
resource "helm_release" "nginx_ingress" {
  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.36.0"

  values = [file("k8s/ingress-controller-values.yaml")]

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-security-groups"
    value = var.eks-security-group-id
    type  = "string"
  }
}

# Descomentar após o primeiro deploy.
#data "kubernetes_service" "ingress-nginx-controller" {
#  metadata {
#    name = "ingress-nginx-controller"
#  }
#}

output "main-lb-hostname" {
  # Descomentar após o primeiro deploy.
  #  value = data.kubernetes_service.ingress-nginx-controller.load_balancer_ingress.0.hostname
  # Comentar após o primeiro deploy.
  value = "replacethisafterfirstdeploy.com"
}
