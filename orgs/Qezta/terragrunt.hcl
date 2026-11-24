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
    "nix build --no-link --print-out-paths '${get_repo_root()}#qezta-github-json' | xargs cat",
  )
}

# Actions environment secrets (terranix/qezta-actions-environments.nix) come
# from Qezta/secrets, not infra-nixCfg-secrets. Override the checkout with
# QEZTA_ORG_SECRETS_REPO.
locals {
  secret      = "${get_repo_root()}/scripts/read-secret"
  org_secrets = get_env("QEZTA_ORG_SECRETS_REPO", "${get_env("HOME")}/Projects/qezta/qezta-secrets")

  actions_secret_sources = {
    metrics_token = "forge/github/metrics.age"
  }
}

inputs = {
  github_actions_secret_values = {
    for name, path in local.actions_secret_sources :
    name => run_cmd("--terragrunt-quiet", "env",
      "QEZTA_SECRETS_REPO=${local.org_secrets}", "QEZTA_SECRETS_REF=origin/main",
    local.secret, path)
  }

  github_token = get_env(
    "GITHUB_TOKEN_QEZTA",
    run_cmd("--terragrunt-quiet", "gh", "auth", "token"),
  )
}
