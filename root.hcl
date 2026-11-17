# State backend. Local by default; set TOFU_REMOTE_STATE=true to use the
# encrypted Cloudflare R2 backend described in docs/remote-state.md.
locals {
  remote = get_env("TOFU_REMOTE_STATE", "false") == "true"

  backends = {
    local = {
      path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
    }
    # R2 speaks the S3 API. use_lockfile needs conditional writes
    # (If-None-Match); verify locking during bootstrap.
    s3 = {
      bucket = get_env("TOFU_STATE_BUCKET", "qezta-tofu-state")
      key    = "${path_relative_to_include()}/tofu.tfstate"
      region = "auto"
      endpoints = {
        s3 = "https://${get_env("CLOUDFLARE_ACCOUNT_ID", "unset")}.r2.cloudflarestorage.com"
      }
      use_lockfile                = true
      use_path_style              = true
      skip_credentials_validation = true
      skip_region_validation      = true
      skip_requesting_account_id  = true
      skip_metadata_api_check     = true
      skip_s3_checksum            = true
    }
  }
}

remote_state {
  backend = local.remote ? "s3" : "local"
  config  = local.backends[local.remote ? "s3" : "local"]
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
