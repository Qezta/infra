include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}//${path_relative_to_include()}"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "github" {
      owner = "Qezta"
      token = var.github_token
    }
  EOF
}

generate "locals" {
  path              = "locals.tf.json"
  if_exists         = "overwrite"
  disable_signature = true
  contents = run_cmd(
    "--terragrunt-quiet",
    "--terragrunt-global-cache",
    "sh", "-c",
    "nix build --no-link --print-out-paths '${get_repo_root()}#qezta-repositories-json' | xargs cat",
  )
}

inputs = {
  github_token = get_env(
    "GITHUB_TOKEN_QEZTA",
    run_cmd("--terragrunt-quiet", "gh", "auth", "token"),
  )
}
