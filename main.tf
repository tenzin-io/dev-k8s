terraform {
  backend "s3" {
    bucket         = "tenzin-io"
    key            = "terraform/dev-k8s.state"
    dynamodb_table = "tenzin-io"
    region         = "us-east-1"
  }
}

module "calico" {
  source = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/calico?ref=main"
}

module "local_path_provisioner" {
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/local-path-provisioner?ref=main"
  depends_on = [module.calico]
}

module "cert_manager" {
  source                     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/cert-manager?ref=main"
  cloudflare_api_token       = var.cloudflare_api_token
  enable_lets_encrypt_issuer = true
  depends_on                 = [module.calico]
}

module "metallb" {
  source        = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/metallb?ref=main"
  ip_pool_range = "192.168.200.230/32"
  depends_on    = [module.calico]
}

module "nginx_ingress" {
  source                  = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/ingress-nginx?ref=main"
  enable_tailscale_tunnel = true
  tailscale_auth_key      = var.tailscale_auth_key
  tailscale_hostname      = "dev-k8s-ingress-nginx"
  depends_on              = [module.metallb, module.cert_manager]
}

module "jupyterhub" {
  depends_on                   = [module.cert_manager, module.nginx_ingress, module.local_path_provisioner]
  source                       = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/jupyterhub?ref=main"
  jupyterhub_fqdn              = "jupyterhub.tenzin.io"
  cert_issuer_name             = module.cert_manager.cert_issuer_name
  enable_github_oauth          = true
  github_oauth_client_id       = var.jupyterhub_github_oauth_client_id
  github_oauth_client_secret   = var.jupyterhub_github_oauth_client_secret
  allowed_github_organizations = ["tenzin-io"]
}

module "prometheus" {
  depends_on = [module.cert_manager, module.local_path_provisioner]
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/prometheus?ref=main"
}

module "grafana" {
  depends_on                 = [module.cert_manager, module.local_path_provisioner, module.prometheus]
  source                     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/grafana?ref=main"
  grafana_fqdn               = "grafana.tenzin.io"
  cert_issuer_name           = module.cert_manager.cert_issuer_name
  enable_github_oauth        = true
  github_oauth_client_id     = var.grafana_github_oauth_client_id
  github_oauth_client_secret = var.grafana_github_oauth_client_secret
  allowed_github_organization = "tenzin-io"
}