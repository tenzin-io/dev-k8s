variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "jupyterhub_github_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "jupyterhub_github_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "grafana_github_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "grafana_github_oauth_client_secret" {
  type      = string
  sensitive = true
}