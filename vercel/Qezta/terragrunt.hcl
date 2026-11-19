# Qezta's Vercel projects (divit, site). Credentials are decrypted at run time
# from DivitMittal/infra-nixCfg-secrets by scripts/read-secret.
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
    "nix build --no-link --print-out-paths '${get_repo_root()}#qezta-vercel-json' | xargs cat",
  )
}

locals {
  secret = "${get_repo_root()}/scripts/read-secret"
}

terraform {
  extra_arguments "credentials" {
    commands = ["init", "plan", "apply", "destroy", "import", "refresh", "output", "state", "validate"]
    env_vars = {
      VERCEL_API_TOKEN = run_cmd("--terragrunt-quiet", local.secret, "cloud/vercel/api_token.age")
    }
  }
}

inputs = {
  gemini_api_key = run_cmd("--terragrunt-quiet", local.secret, "ai/gemini.age")
}
