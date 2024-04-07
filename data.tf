data "vault_generic_secret" "cloudflare" {
  path = "secrets/cloudflare"
}

data "vault_generic_secret" "tailscale" {
  path = "secrets/tailscale/kubernetes_ingress"
}
