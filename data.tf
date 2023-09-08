data "vault_generic_secret" "github_app" {
  path = "secrets/github_app"
}

data "vault_generic_secret" "cloudflare" {
  path = "secrets/cloudflare"
}

data "vault_generic_secret" "xmatters" {
  path = "secrets/xmatters"
}

data "vault_generic_secret" "grafana_dev" {
  path = "secrets/grafana-dev"
}

data "vault_generic_secret" "tailscale" {
  path = "secrets/tailscale"
}
