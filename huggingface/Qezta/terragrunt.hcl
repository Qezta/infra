# Qezta's Hugging Face organization (huggingface.co/Qezta): model repositories
# and the org card. Source: terranix/qezta-huggingface.nix.
#
# HF_TOKEN is decrypted at run time from Qezta/secrets (forge/huggingface/tofu.age),
# not infra-nixCfg-secrets, because it's an org credential. Override the checkout
# with QEZTA_ORG_SECRETS_REPO, or skip decryption by exporting HF_TOKEN_QEZTA.
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
    "nix build --no-link --print-out-paths '${get_repo_root()}#qezta-huggingface-json' | xargs cat",
  )
}

locals {
  secret      = "${get_repo_root()}/scripts/read-secret"
  org_secrets = get_env("QEZTA_ORG_SECRETS_REPO", "${get_env("HOME")}/Projects/qezta/secrets")
  # Terragrunt evaluates both arms of an HCL conditional, so the override is
  # handled in the shell: an exported HF_TOKEN_QEZTA means nothing is decrypted.
  hf_token = run_cmd(
    "--terragrunt-quiet", "sh", "-c",
    "if [ -n \"$${HF_TOKEN_QEZTA:-}\" ]; then printf %s \"$HF_TOKEN_QEZTA\"; else QEZTA_SECRETS_REPO='${local.org_secrets}' QEZTA_SECRETS_REF=origin/main '${local.secret}' forge/huggingface/tofu.age; fi",
  )
}

terraform {
  extra_arguments "credentials" {
    commands = ["init", "plan", "apply", "destroy", "import", "refresh", "output", "state", "validate"]
    env_vars = {
      # Read by the m11s-io/huggingface provider and by the org card scripts.
      HF_TOKEN = local.hf_token
      HF_HUB_DISABLE_TELEMETRY = "1"
    }
  }
}
