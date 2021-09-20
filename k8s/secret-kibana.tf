#
## Kibanas Secret
#
data "aws_secretsmanager_secret_version" "devops-kibana-proxy-creds" {
  secret_id = "devops-kibana-proxy-creds"
}

data "dns_cname_record_set" "elasticsearch-real-hostname" {
  host = var.elasticsearch-host
}

locals {
  devops-kibana-proxy-creds = jsondecode(
    data.aws_secretsmanager_secret_version.devops-kibana-proxy-creds.secret_string
  )
  elasticsearch-real-hostname = trimsuffix(
    data.dns_cname_record_set.elasticsearch-real-hostname.cname, "."
  )
}

resource "kubernetes_secret" "kibana-auth" {
  metadata {
    name      = "kibana-auth"
    namespace = "devops"
  }

  data = {
    "auth" = "${local.devops-kibana-proxy-creds.username}:${local.devops-kibana-proxy-creds.bcrypted-password}"
  }
}
