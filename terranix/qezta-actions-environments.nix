## GitHub Actions environments and their secrets for Qezta repos.
##
## Each secret maps to a logical source key. orgs/Qezta/terragrunt.hcl maps
## every key to an age file in Qezta/secrets and decrypts it at plan time with
## scripts/read-secret, passing the values in as var.github_actions_secret_values.
##
## Shape: { <repo> = { <environment> = { existing = bool; secrets = { NAME = source-key; }; }; }; }
##   existing  true (default) = already on GitHub, adopt with an import block
{lib, ...}: let
  environments = {
    ".github" = {
      ## Qezta/.github flake/actions/metrics.nix: lowlighter/metrics needs a
      ## user PAT (classic: public_repo, read:user, read:org).
      production.secrets.METRICS_TOKEN = "metrics_token";
    };
  };

  envList = lib.concatLists (lib.mapAttrsToList (repo: envs:
    lib.mapAttrsToList (env: cfg: {inherit repo env cfg;}) envs)
  environments);

  secretList = lib.concatMap (e:
    lib.mapAttrsToList (name: source: {
      inherit (e) repo env;
      inherit name source;
    })
    (e.cfg.secrets or {}))
  envList;

  envKey = e: "${e.repo}:${e.env}";
  secretKey = s: "${s.repo}:${s.env}:${s.name}";
in {
  variable.github_actions_secret_values = {
    description = "Decrypted Actions secret values keyed by logical source key (see orgs/Qezta/terragrunt.hcl).";
    type = "map(string)";
    sensitive = true;
  };

  ## One resource block each, instanced with for_each over these locals.
  locals.actions_environments = lib.listToAttrs (map (e: {
      name = envKey e;
      value = {inherit (e) repo env;};
    })
    envList);

  locals.actions_environment_secrets = lib.listToAttrs (map (s: {
      name = secretKey s;
      value = {
        inherit (s) repo name source;
        env_key = "${s.repo}:${s.env}";
      };
    })
    secretList);

  resource.github_repository_environment.actions = {
    for_each = "\${local.actions_environments}";
    repository = "\${github_repository.repos[each.value.repo].name}";
    environment = "\${each.value.env}";
  };

  resource.github_actions_environment_secret.actions = {
    for_each = "\${local.actions_environment_secrets}";
    repository = "\${github_repository.repos[each.value.repo].name}";
    environment = "\${github_repository_environment.actions[each.value.env_key].environment}";
    secret_name = "\${each.value.name}";
    plaintext_value = "\${var.github_actions_secret_values[each.value.source]}";
  };

  import = map (e: {
    to = "github_repository_environment.actions[\"${envKey e}\"]";
    id = envKey e;
  }) (builtins.filter (e: e.cfg.existing or true) envList);
}
