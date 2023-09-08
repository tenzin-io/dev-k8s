terraform {
  backend "s3" {
    bucket         = "tenzin-io"
    key            = "terraform/homelab-k8s-dev.state"
    dynamodb_table = "tenzin-io"
    region         = "us-east-1"
  }
}

module "cert_manager" {
  source                  = "git::https://github.com/tenzin-io/terraform-tenzin-cert-manager.git?ref=v0.0.2"
  cert_registration_email = "tenzin@tenzin.io"
  cloudflare_api_token    = data.vault_generic_secret.cloudflare.data.api_token
}

module "github_actions" {
  source                     = "git::https://github.com/tenzin-io/terraform-tenzin-github-actions-runner-controller.git?ref=v0.2.0"
  github_org_name            = "tenzin-io"
  github_app_id              = data.vault_generic_secret.github_app.data.app_id
  github_app_installation_id = data.vault_generic_secret.github_app.data.installation_id
  github_app_private_key     = data.vault_generic_secret.github_app.data.private_key
  github_runner_labels       = ["homelab", "dev"]
  github_runner_image        = "containers.tenzin.io/docker/tenzin-io/actions-runner-images/ubuntu-latest:v0.0.7"
  depends_on                 = [module.cert_manager]
}

module "metallb" {
  source        = "git::https://github.com/tenzin-io/terraform-tenzin-metallb.git?ref=v0.0.1"
  ip_pool_range = "192.168.200.71/32"
}

module "nginx_ingress" {
  source                  = "git::https://github.com/tenzin-io/terraform-tenzin-nginx-ingress-controller.git?ref=v0.0.2"
  enable_tailscale_tunnel = true
  tailscale_auth_key      = data.vault_generic_secret.tailscale.data.auth_key
  depends_on              = [module.metallb, module.cert_manager]
}

module "nfs_subdir" {
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-nfs-subdir.git?ref=v0.0.4"
  nfs_server = "zfs-1.tenzin.io"
  nfs_path   = "/data/homelab-k8s-dev"
}

module "prometheus" {
  source                  = "git::https://github.com/tenzin-io/terraform-tenzin-prometheus.git?ref=main"
  alert_receiver_name     = "xmatters"
  alert_receiver_username = data.vault_generic_secret.xmatters.data.username
  alert_receiver_password = data.vault_generic_secret.xmatters.data.password
  alert_receiver_url      = data.vault_generic_secret.xmatters.data.trigger_url
  kubernetes_cluster_name = "homelab-k8s-dev"
  prometheus_volume_size  = "30Gi"
  certificate_issuer_name = "lets-encrypt"
  thanos_ingress_host     = "thanos-homelab-k8s-dev.tenzin.io"
}

module "grafana" {
  source                     = "git::https://github.com/tenzin-io/terraform-tenzin-grafana.git?ref=v0.0.2"
  grafana_ingress_host       = "grafana-dev.tenzin.io"
  certificate_issuer_name    = "lets-encrypt"
  github_org_name            = "tenzin-io"
  github_oauth_client_id     = data.vault_generic_secret.grafana_dev.data.github_oauth_client_id
  github_oauth_client_secret = data.vault_generic_secret.grafana_dev.data.github_oauth_client_secret
  thanos_store_endpoints     = ["thanos-homelab-k8s-dev.tenzin.io:443"]
  depends_on                 = [module.nginx_ingress, module.cert_manager, module.prometheus]
}
