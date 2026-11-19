## Qezta's Vercel projects: Git links, domains and environment variables.
## The projects already exist (re-linked from the old qezta-website monorepo
## on 2026-11-19) and are adopted with import blocks.
{lib, ...}: let
  team = "team_niNYtJlHGjDXFsSzntAp6eNH"; # divit-mittals-projects

  projects = {
    divit = {
      id = "prj_ic8E9d2QWI3dRQzqFIQiNIV3Cq0S";
      repo = "Qezta/divit";
      domains = ["divit.qezta.com" "www.divit.qezta.com"];
    };
    site = {
      id = "prj_szHMwhdvbqe9p6ZodaKI0iAfm7e4";
      repo = "Qezta/site";
      domains = ["qezta.com" "www.qezta.com"];
    };
  };

  domainKey = d: lib.replaceStrings ["."] ["_"] d;
  domains = lib.concatLists (lib.mapAttrsToList (project: p:
    map (d: {
      inherit project d;
      inherit (p) id;
    })
    p.domains)
  projects);
in {
  terraform.required_version = ">= 1.11";
  terraform.required_providers.vercel = {
    source = "vercel/vercel";
    version = "~> 5.27";
  };
  ## Token from VERCEL_API_TOKEN (scripts/read-secret cloud/vercel/api_token.age).
  provider.vercel.team = team;

  ## Write-only (value_wo) and ephemeral: the key reaches Vercel but is never
  ## stored in OpenTofu state.
  variable.gemini_api_key = {
    description = "Gemini API key for divit's chatbot (ai/gemini.age).";
    type = "string";
    sensitive = true;
    ephemeral = true;
  };

  resource = {
    vercel_project =
      lib.mapAttrs (name: p: {
        inherit name;
        framework = "sveltekit-1";
        node_version = "24.x";
        output_directory = ".svelte-kit/output";
        resource_config = {
          fluid = true;
          function_default_regions = ["iad1"];
        };
        git_repository = {
          type = "github";
          inherit (p) repo;
          production_branch = "main";
        };
        lifecycle.prevent_destroy = true;
      })
      projects;

    vercel_project_domain = lib.listToAttrs (map (x:
      lib.nameValuePair (domainKey x.d) {
        project_id = "\${vercel_project.${x.project}.id}";
        domain = x.d;
        redirect =
          if x.d == "qezta.com"
          then "www.qezta.com"
          else null;
        redirect_status_code =
          if x.d == "divit.qezta.com"
          then 307
          else null;
      })
    domains);

    ## divit's /api/chat reads GEMINI_API_KEY at run time.
    vercel_project_environment_variable.divit_gemini = {
      project_id = "\${vercel_project.divit.id}";
      key = "GEMINI_API_KEY";
      value_wo = "\${var.gemini_api_key}";
      ## Bump to push a rotated key (write-only values can't be diffed).
      value_wo_version = 1;
      target = ["production" "preview"];
      sensitive = true;
      comment = "RAG chatbot (src/routes/api/chat)";
    };
  };

  import =
    lib.mapAttrsToList (name: p: {
      to = "vercel_project.${name}";
      inherit (p) id;
    })
    projects
    ++ map (x: {
      to = "vercel_project_domain.${domainKey x.d}";
      id = "${x.id}/${x.d}";
    })
    domains;
}
