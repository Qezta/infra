{
  terraform.required_version = ">= 1.7.0";

  terraform.required_providers.cloudflare = {
    source = "cloudflare/cloudflare";
    version = "~> 5.0";
  };

  terraform.required_providers.spaceship = {
    source = "namecheap/spaceship";
    version = "~> 1.0";
  };

  provider.cloudflare = {};
  provider.spaceship = {};

  variable.cloudflare_api_token = {
    description = "Cloudflare API token with the minimum required DNS permissions.";
    type = "string";
    sensitive = true;
  };

  variable.spaceship_api_key = {
    description = "Spaceship API key. Prefer SPACESHIP_API_KEY in the environment.";
    type = "string";
    sensitive = true;
  };

  variable.spaceship_api_secret = {
    description = "Spaceship API secret. Prefer SPACESHIP_API_SECRET in the environment.";
    type = "string";
    sensitive = true;
  };
}
