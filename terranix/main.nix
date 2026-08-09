{
  terraform.required_version = ">= 1.7.0";

  terraform.required_providers.cloudflare = {
    source = "cloudflare/cloudflare";
    version = "~> 5.0";
  };

  provider.cloudflare = {};

  variable.cloudflare_api_token = {
    description = "Cloudflare API token with the minimum required DNS permissions.";
    type = "string";
    sensitive = true;
  };
}
