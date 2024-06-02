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
  source                   = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/ingress-nginx?ref=main"
  enable_cloudflare_tunnel = true
  cloudflare_tunnel_token  = var.cloudflare_tunnel_token
  depends_on               = [module.metallb, module.cert_manager]
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
  depends_on                  = [module.cert_manager, module.local_path_provisioner, module.prometheus]
  source                      = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/grafana?ref=main"
  grafana_fqdn                = "grafana.tenzin.io"
  cert_issuer_name            = module.cert_manager.cert_issuer_name
  enable_github_oauth         = true
  github_oauth_client_id      = var.grafana_github_oauth_client_id
  github_oauth_client_secret  = var.grafana_github_oauth_client_secret
  allowed_github_organization = "tenzin-io"
}

module "actions_runner" {
  source                     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/actions-runner?ref=main"
  runner_set_name            = "dev-k8s"
  runner_image               = "ghcr.io/tenzin-io/actions-runner:v0.0.1"
  github_organization_url    = "https://github.com/tenzin-io"
  github_app_id              = var.actions_runner_github_app_id
  github_app_installation_id = var.actions_runner_github_app_installation_id
  github_app_private_key     = var.actions_runner_github_app_private_key
}