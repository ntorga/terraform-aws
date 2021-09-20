#
## kibana-proxy Deployment & Service
#
locals {
  kibana-proxy-subdomain       = "kibana.${var.stage-domain}"
  kibana-proxy-nginx-conf-file = "${local.kibana-proxy-subdomain}.conf"
}

resource "kubernetes_config_map" "kibana-proxy-conf" {
  metadata {
    name      = "kibana-proxy-conf"
    namespace = "devops"
  }

  data = {
    (local.kibana-proxy-nginx-conf-file) = <<EOF
server {
    listen      80;
    listen      [::]:80;
    server_name ${local.kibana-proxy-subdomain};

    rewrite ^/$ https://${local.kibana-proxy-subdomain}/_plugin/kibana redirect;

    # logging
    access_log off;
    error_log /dev/stderr warn;

    # reverse proxy
    location /_plugin/kibana {
      proxy_pass                         https://${local.elasticsearch-real-hostname}/_plugin/kibana;
      proxy_http_version                 1.1;
      proxy_cache_bypass                 $http_upgrade;

      # Proxy headers
      proxy_set_header Host              ${local.elasticsearch-real-hostname};
      proxy_set_header X-Real-IP         $remote_addr;
      proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host  ${local.kibana-proxy-subdomain};
      proxy_set_header X-Forwarded-Port  $server_port;

      # Proxy timeouts
      proxy_connect_timeout              60s;
      proxy_send_timeout                 60s;
      proxy_read_timeout                 60s;

      # Update cookie domain and path
      proxy_cookie_domain ${local.elasticsearch-real-hostname} ${local.kibana-proxy-subdomain};
      proxy_cookie_path / /_plugin/kibana/;

      # Response buffer settings
      proxy_buffer_size 128k;
      proxy_buffers 4 256k;
      proxy_busy_buffers_size 256k;
    }
}

# subdomains redirect
server {
    listen      80;
    listen      [::]:80;
    server_name *.${local.kibana-proxy-subdomain};
    return      301 http://${local.kibana-proxy-subdomain}$request_uri;
}
EOF
  }
}

resource "kubernetes_deployment" "kibana-proxy" {
  metadata {
    name      = "kibana-proxy"
    namespace = "devops"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kibana-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "kibana-proxy"
        }
        # Access logs are ignored cause we get those logs from the Ing. Controller.
        annotations = {
          "fluentbit.io/parser_stderr"  = "nginx_error"
          "fluentbit.io/exclude_stdout" = true
        }
      }
      spec {
        volume {
          name = "kibana-proxy-conf"
          config_map {
            name = "kibana-proxy-conf"
          }
        }
        container {
          image = "nginx:stable-alpine"
          name  = "kibana-proxy"
          port {
            container_port = 80
          }
          resources {
            limits {
              cpu    = var.stage-container-limits.micro.cpu
              memory = var.stage-container-limits.micro.memory
            }
          }
          volume_mount {
            name       = "kibana-proxy-conf"
            mount_path = "/etc/nginx/conf.d/"
            read_only  = true
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kibana-proxy" {
  metadata {
    name      = "kibana-proxy"
    namespace = "devops"
  }
  spec {
    selector = {
      app = "kibana-proxy"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}
