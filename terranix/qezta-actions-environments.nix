## GitHub Actions environment definitions for Qezta repos, absorbed from
## forge-tofu's terranix/orgs/Qezta.nix during the 2026-11 migration.
##
## NOT WIRED into qezta-github.nix yet: forge-tofu never applied these, and
## their agenix source paths (api/gemini.age, vercel/*.age, ...) no longer exist
## after the infra-nixCfg-secrets reorganisation. Wire them in once each
## logical source key below maps to a real secret path.
##
## Shape: { <repo> = { <environment> = { secrets = { NAME = source-key; }; variables = {}; }; }; }
{
  ".github" = {
    production = {
      secrets = {};
      variables = {};
    };
  };
}
