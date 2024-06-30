data "vault_generic_secret" "cloudflare" {
  path = "secrets/cloudflare"
}

data "vault_generic_secret" "grafana" {
  path = "secrets/grafana"
}

data "vault_generic_secret" "jupyterhub" {
  path = "secrets/jupyterhub"
}

data "vault_generic_secret" "github_tenzin_org" {
  path = "secrets/github-actions/tenzin-io"
}

data "vault_generic_secret" "github_tlhakhan_user" {
  path = "secrets/github-actions/tlhakhan"
}