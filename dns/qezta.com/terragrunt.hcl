# qezta.com DNS on Cloudflare and the nameserver cutover at Spaceship.
# Runbook: docs/dns-migration.md.
#
# Credentials are decrypted at run time from DivitMittal/infra-nixCfg-secrets
# (scripts/read-secret, cloud/{cloudflare,spaceship}/*.age) and handed to the
# providers through the environment. Stage flags: QEZTA_DNS_CUTOVER,
# QEZTA_DNS_DNSSEC.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

generate "terranix" {
  path              = "main.tf.json"
  if_exists         = "overwrite"
  disable_signature = true
  contents = run_cmd(
    "--terragrunt-quiet",
    "--terragrunt-global-cache",
    "sh", "-c",
    "nix build --no-link --print-out-paths '${get_repo_root()}#qezta-dns-json' | xargs cat",
  )
}

locals {
  secret = "${get_repo_root()}/scripts/read-secret"
}

terraform {
  extra_arguments "credentials" {
    commands = ["init", "plan", "apply", "destroy", "import", "refresh", "output", "state", "validate"]
    env_vars = {
      CLOUDFLARE_API_TOKEN = run_cmd("--terragrunt-quiet", local.secret, "cloud/cloudflare/api_token.age")
      SPACESHIP_API_KEY    = run_cmd("--terragrunt-quiet", local.secret, "cloud/spaceship/api_key.age")
      SPACESHIP_API_SECRET = run_cmd("--terragrunt-quiet", local.secret, "cloud/spaceship/api_secret.age")
    }
  }

  # Moving nameservers while the registry still publishes Spaceship's DS
  # record would make every validating resolver reject qezta.com.
  before_hook "dnssec_guard" {
    commands = ["plan", "apply"]
    execute = ["sh", "-c", <<-EOT
      if [ "$${QEZTA_DNS_CUTOVER:-false}" = true ] && [ -n "$(dig +short DS qezta.com)" ]; then
        echo "Refusing the cutover: a DS record for qezta.com is still published." >&2
        echo "Turn DNSSEC off at Spaceship and wait for the DS TTL to pass (docs/dns-migration.md)." >&2
        exit 1
      fi
    EOT
    ]
  }
}

inputs = {
  cloudflare_account_id = run_cmd("--terragrunt-quiet", local.secret, "cloud/cloudflare/account_id.age")
  email_forward_to      = run_cmd("--terragrunt-quiet", local.secret, "cloud/cloudflare/email_forward_to.age")
  cutover               = get_env("QEZTA_DNS_CUTOVER", "false") == "true"
  enable_dnssec         = get_env("QEZTA_DNS_DNSSEC", "false") == "true"
}
