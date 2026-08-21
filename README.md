# Qezta Infrastructure

Terranix configuration for Qezta infrastructure, starting with domain and DNS management.

## Development

Requires Nix with flakes enabled and Spaceship API credentials. Cloudflare remains available for hosted DNS zones, while Spaceship manages registrar domains and Spaceship DNS.

```sh
nix develop
terraform init
export SPACESHIP_API_KEY=...
export SPACESHIP_API_SECRET=...
terraform plan
```

Terraform JSON is generated from `terranix/main.nix` with:

```sh
nix build .#terraform-json
```

## Qezta GitHub repositories

Repository management is implemented entirely in Terranix under
`terranix/qezta-github.nix` and `terranix/qezta-repositories.nix`.

```sh
cd orgs/Qezta
terragrunt init
terragrunt plan
```

Set `GITHUB_TOKEN_QEZTA` with a token authorized to manage the Qezta
organization. Configure a remote state backend before the first apply.

Do not commit Terraform state, variable files, or API tokens. Configure a remote encrypted backend before applying changes.

## Spaceship DNS

The Spaceship provider is declared in `terranix/main.nix`. Add domains and records only after inventorying the current WebUI configuration. Spaceship DNS record resources represent the complete record set for a domain; records omitted from Terraform may be removed during apply.

Import existing resources before the first apply and review the plan carefully.
