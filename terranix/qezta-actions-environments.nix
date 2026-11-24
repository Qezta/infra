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

  resource.github_repository_environment.actions = lib.listToAttrs (map (e: {
      name = envKey e;
      value = {
        repository = "\${github_repository.repos[\"${e.repo}\"].name}";
        environment = e.env;
      };
    })
    envList);

  resource.github_actions_environment_secret.actions = lib.listToAttrs (map (s: {
      name = secretKey s;
      value = {
        repository = "\${github_repository.repos[\"${s.repo}\"].name}";
        environment = "\${github_repository_environment.actions[\"${s.repo}:${s.env}\"].environment}";
        secret_name = s.name;
        plaintext_value = "\${var.github_actions_secret_values[\"${s.source}\"]}";
      };
    })
    secretList);

  import = map (e: {
    to = "github_repository_environment.actions[\"${envKey e}\"]";
    id = envKey e;
  }) (builtins.filter (e: e.cfg.existing or true) envList);
}
