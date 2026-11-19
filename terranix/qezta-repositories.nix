## Canonical repository map for the Qezta GitHub organisation.
## Values mirror what is live on GitHub (absorbed from forge-tofu's
## terranix/orgs/Qezta.nix during the 2026-11 migration).
##
## Optional per-repo keys:
##   homepage_url            string
##   workflow_permissions    "read" (default) | "write" — GITHUB_TOKEN default
##   actions_can_create_prs  bool (default true)
##   existing                bool (default true); false = create, don't import
##   required_checks         [string] (default []) status checks the default-branch
##                           ruleset requires; only list workflows that run on every PR
##   ruleset_require_pr      bool (default true) require pull requests on the
##                           default branch; false where a workflow commits straight
##                           to it (e.g. gen-sitemap), since GitHub Actions can't be a
##                           ruleset bypass actor in this org
##   require_signed_commits  bool (default false)
##   archived                bool (default false); archived repos get no
##                           ruleset or Actions settings (they're read-only)
{
  ".github" = {
    description = "Qezta org profile";
    visibility = "public";
    topics = ["organization-profile" "profile" "qezta"];
    delete_branch_on_merge = false;
  };
  "divit" = {
    description = "divit.qezta.com: personal portfolio with Gemini-powered RAG chatbot";
    homepage_url = "https://divit.qezta.com";
    visibility = "public";
    topics = ["gemini" "personal-website" "portfolio" "qezta" "rag" "svelte" "sveltekit" "typescript" "vercel"];
    delete_branch_on_merge = false;
  };
  "company" = {
    description = "Qezta's company spec: people, roles, policies, processes and finance as code (private)";
    visibility = "private";
    topics = ["business-as-code" "company-as-code" "nix" "qezta"];
    delete_branch_on_merge = true;
    existing = false;
  };
  "company-framework" = {
    description = "Typed Nix description of a company that compiles to community-standard formats";
    visibility = "public";
    topics = ["backstage" "business-as-code" "company-as-code" "nix" "nix-flake" "openslo" "opa" "qezta"];
    delete_branch_on_merge = true;
    existing = false;
    ## Its CI runs on every pull request.
    required_checks = ["check" "template"];
  };
  "infra" = {
    description = "Qezta's infrastructure as code: GitHub org, repositories, teams and DNS (OpenTofu, Terranix, Terragrunt)";
    visibility = "public";
    topics = ["dns" "github" "infrastructure" "nix" "opentofu" "qezta" "spaceship" "terragrunt" "terranix"];
    delete_branch_on_merge = false;
    ## Live value at migration time; flip to "read" once its workflows all
    ## declare `permissions:` explicitly.
    workflow_permissions = "write";
  };
  "qezta-website" = {
    ## Decommissioned 2026-11-19: divit.qezta.com and qezta.com now deploy
    ## from Qezta/divit and Qezta/site (Vercel projects divit and site).
    description = "Archived: superseded by Qezta/divit (divit.qezta.com) and Qezta/site (qezta.com)";
    homepage_url = "https://qezta.com";
    visibility = "public";
    topics = ["archived" "qezta" "svelte" "vercel"];
    delete_branch_on_merge = false;
    archived = true;
  };
  "site" = {
    description = "qezta.com: marketing site for Qezta";
    homepage_url = "https://qezta.com";
    visibility = "public";
    topics = ["marketing" "qezta" "svelte" "sveltekit" "typescript" "website"];
    delete_branch_on_merge = false;
  };
  "ssh" = {
    description = "ssh divit@qezta.com: SSH terminal portfolio mirroring divit.qezta.com, built on wish + Bubble Tea";
    visibility = "public";
    topics = ["bubbletea" "go" "portfolio" "qezta" "ssh" "tui" "wish"];
    delete_branch_on_merge = false;
  };
  "ui" = {
    description = "Shared Svelte component library and design system for Qezta org sub-products";
    visibility = "public";
    topics = ["component-library" "design-system" "qezta" "svelte" "typescript"];
    delete_branch_on_merge = false;
  };
  "secrets" = {
    description = "Encrypted secrets for Qezta infrastructure and CI";
    visibility = "private";
    topics = ["agenix" "infrastructure" "nix" "qezta" "secrets"];
    delete_branch_on_merge = false;
    ## Live value at migration time; see note on "infra".
    workflow_permissions = "write";
  };
}
