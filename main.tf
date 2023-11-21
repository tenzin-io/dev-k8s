terraform {
  backend "s3" {
    bucket         = "tenzin-io"
    key            = "terraform/dev-k8s.state"
    dynamodb_table = "tenzin-io"
    region         = "us-east-1"
  }
}

module "cert_manager" {
  source                  = "git::https://github.com/tenzin-io/terraform-tenzin-cert-manager.git?ref=v0.0.2"
  cert_registration_email = "tenzin@tenzin.io"
  cloudflare_api_token    = data.vault_generic_secret.cloudflare.data.api_token
}

module "metallb" {
  source        = "git::https://github.com/tenzin-io/terraform-tenzin-metallb.git?ref=v0.0.1"
  ip_pool_range = "192.168.200.240/32"
}

module "nginx_ingress" {
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-nginx-ingress-controller.git?ref=v0.0.2"
  depends_on = [module.metallb, module.cert_manager]
}

module "nfs_subdir" {
  source     = "git::https://github.com/tenzin-io/terraform-tenzin-nfs-subdir.git?ref=v0.0.4"
  nfs_server = "zfs-1"
  nfs_path   = "/data/dev-k8s"
}
