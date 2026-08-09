# Qezta Infrastructure

Terraform configuration for Qezta infrastructure, starting with domain and DNS management.

## Development

Requires Nix with flakes enabled and a Cloudflare API token supplied through Terraform variables.

```sh
nix develop
terraform init
terraform plan -var='cloudflare_api_token=...'
```

Do not commit Terraform state, variable files, or API tokens. Configure a remote encrypted backend before applying changes.
