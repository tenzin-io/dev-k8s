terraform {
  required_version = "~> 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

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
  cloudflare_api_token       = data.vault_generic_secret.cloudflare.data["cloudflare_api_token"]
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
  cloudflare_tunnel_token  = data.vault_generic_secret.cloudflare.data["cloudflare_tunnel_token"]
  depends_on               = [module.metallb, module.cert_manager]
}

module "jupyterhub" {
  depends_on                   = [module.cert_manager, module.nginx_ingress, module.local_path_provisioner]
  source                       = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/jupyterhub?ref=main"
  jupyterhub_fqdn              = "jupyterhub.tenzin.io"
  cert_issuer_name             = module.cert_manager.cert_issuer_name
  enable_github_oauth          = true
  github_oauth_client_id       = data.vault_generic_secret.jupyterhub.data["github_oauth_client_id"]
  github_oauth_client_secret   = data.vault_generic_secret.jupyterhub.data["github_oauth_client_secret"]
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
  github_oauth_client_id      = data.vault_generic_secret.grafana.data["github_oauth_client_id"]
  github_oauth_client_secret  = data.vault_generic_secret.grafana.data["github_oauth_client_secret"]
  allowed_github_organization = "tenzin-io"
}

module "actions_runner" {
  source = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/actions-runner?ref=main"
}

module "actions_runner_user" {
  depends_on      = [module.actions_runner]
  runner_set_name = "tlhakhan"
  source          = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/actions-runner-set?ref=main"
  runner_image    = "ghcr.io/tenzin-io/actions-runner:0.0.2"
  github_config_urls = [
    "https://github.com/tlhakhan/learn-wasm",
    "https://github.com/tlhakhan/learn-rust"
  ]
  github_app_id              = data.vault_generic_secret.github_tlhakhan_user.data["github_app_id"]
  github_app_installation_id = data.vault_generic_secret.github_tlhakhan_user.data["github_app_installation_id"]
  github_app_private_key     = data.vault_generic_secret.github_tlhakhan_user.data["github_app_private_key"]
}

module "actions_runner_org" {
  depends_on                 = [module.actions_runner]
  runner_set_name            = "tenzin-io"
  source                     = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/actions-runner-set?ref=main"
  runner_image               = "ghcr.io/tenzin-io/actions-runner:0.0.2"
  github_config_urls         = ["https://github.com/tenzin-io"]
  github_app_id              = data.vault_generic_secret.github_tenzin_org.data["github_app_id"]
  github_app_installation_id = data.vault_generic_secret.github_tenzin_org.data["github_app_installation_id"]
  github_app_private_key     = data.vault_generic_secret.github_tenzin_org.data["github_app_private_key"]
}

module "external_services" {
  source = "git::https://github.com/tenzin-io/terraform-tenzin-homelab.git//kubernetes/external-services?ref=main"
  external_services = {
    "pypi-cache" = {
      address = "tenzins-ubuntu.lan"
      port    = "80"
    }
  }
  external_domain_name = "tenzin.io"
  certificate_issuer   = "lets-encrypt"
}