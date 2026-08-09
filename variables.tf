variable "cloudflare_api_token" {
  description = "Cloudflare API token with the minimum required DNS permissions."
  type        = string
  sensitive   = true
}
