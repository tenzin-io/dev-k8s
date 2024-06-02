variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_tunnel_token" {
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

variable "actions_runner_github_app_id" {
  type      = string
  sensitive = true
}

variable "actions_runner_github_app_installation_id" {
  type      = string
  sensitive = true
}

variable "actions_runner_github_app_private_key" {
  type      = string
  sensitive = true
}