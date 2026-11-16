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

  "qezta-website" = {
    "Production – qezta-website-divit" = {
      secrets = {
        GH_TOKEN = "github";
        GEMINI_API_KEY = "gemini";
        GROQ_API_KEY = "groq";
        HF_TOKEN = "hf";
        OPENROUTER_API_KEY = "openrouter";
        OPENCODE_API_KEY = "opencode";
        DISCORD_TOKEN = "discord";
        GOOGLE_CLIENT_ID = "google_client_id";
        GOOGLE_CLIENT_SECRET = "google_client_secret";
        VERCEL_TOKEN = "vercel_token";
        VERCEL_ORG_ID = "vercel_org_id";
        VERCEL_PROJECT_ID = "vercel_project_id_qezta_website_divit";
      };
      variables = {};
    };

    "Production – qezta-website-qezta" = {
      secrets = {
        GH_TOKEN = "github";
        GEMINI_API_KEY = "gemini";
        GROQ_API_KEY = "groq";
        HF_TOKEN = "hf";
        OPENROUTER_API_KEY = "openrouter";
        OPENCODE_API_KEY = "opencode";
        DISCORD_TOKEN = "discord";
        GOOGLE_CLIENT_ID = "google_client_id";
        GOOGLE_CLIENT_SECRET = "google_client_secret";
        VERCEL_TOKEN = "vercel_token";
        VERCEL_ORG_ID = "vercel_org_id";
        VERCEL_PROJECT_ID = "vercel_project_id_qezta_website_qezta";
      };
      variables = {};
    };
  };
}
