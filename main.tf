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
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/cert-manager?ref=main"
  cloudflare_api_token    = var.cloudflare_api_token
  enable_lets_encrypt_issuer = true
}

module "metallb" {
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/metallb?ref=main"
  ip_pool_range = "192.168.200.230/32"
}

#
#module "nginx_ingress" {
#  source                  = "git::https://github.com/tenzin-io/terraform-tenzin-nginx-ingress-controller.git?ref=v0.0.3"
#  depends_on              = [module.metallb, module.cert_manager]
#  enable_tailscale_tunnel = true
#  tailscale_auth_key      = data.vault_generic_secret.tailscale.data.tailscale_auth_key
#
#}
#
#module "nfs_subdir" {
#  source     = "git::https://github.com/tenzin-io/terraform-tenzin-nfs-subdir.git?ref=v0.0.4"
#  nfs_server = "localhost"
#  nfs_path   = "/data"
#}
#
#module "jupyterhub" {
#  source                       = "git::https://github.com/tenzin-io/terraform-tenzin-jupyterhub.git?ref=v0.0.1"
#  jupyterhub_fqdn              = "jupyterhub.tenzin.io"
#  cert_issuer_name             = module.cert_manager.cert_issuer_name
#  github_oauth_client_id       = data.vault_generic_secret.jupyterhub.data.github_oauth_client_id
#  github_oauth_client_secret   = data.vault_generic_secret.jupyterhub.data.github_oauth_client_secret
#  allowed_github_organizations = ["tenzin-io", "tenzinlab"]
#}
#