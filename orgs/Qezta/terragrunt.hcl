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

inputs = {
  github_token = get_env(
    "GITHUB_TOKEN_QEZTA",
    run_cmd("--terragrunt-quiet", "gh", "auth", "token"),
  )
}
