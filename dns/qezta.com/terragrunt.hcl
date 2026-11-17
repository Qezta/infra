# Email DNS records for qezta.com (Spaceship). Needs SPACESHIP_API_KEY and
# SPACESHIP_API_SECRET in the environment; see terranix/qezta-dns.nix.
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
