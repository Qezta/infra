# qezta.com DNS on Cloudflare and the nameserver cutover at Spaceship.
# Runbook: docs/dns-migration.md.
#
# Environment: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID,
# SPACESHIP_API_KEY, SPACESHIP_API_SECRET, QEZTA_EMAIL_FORWARD_TO, and the
# stage flags QEZTA_DNS_CUTOVER / QEZTA_DNS_DNSSEC.
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

terraform {
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
  cloudflare_account_id = get_env("CLOUDFLARE_ACCOUNT_ID", "")
  email_forward_to      = get_env("QEZTA_EMAIL_FORWARD_TO", "")
  cutover               = get_env("QEZTA_DNS_CUTOVER", "false") == "true"
  enable_dnssec         = get_env("QEZTA_DNS_DNSSEC", "false") == "true"
}
