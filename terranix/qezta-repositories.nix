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
##   ruleset_bypass_actions  bool (default false) let GitHub Actions push to the
##                           default branch (workflows that commit, e.g. gen-sitemap)
##   require_signed_commits  bool (default false)
{
  ".github" = {
    description = "Qezta org profile";
    visibility = "public";
    topics = ["organization-profile" "profile" "qezta"];
    delete_branch_on_merge = false;
  };
  "divit" = {
    ## gen-sitemap.yml commits straight to the default branch.
    ruleset_bypass_actions = true;
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
    ## gen-sitemap.yml commits straight to the default branch.
    ruleset_bypass_actions = true;
    description = "Qezta Website";
    homepage_url = "https://www.Qezta.com";
    visibility = "public";
    topics = ["flake-parts" "nix" "personal-website" "qezta" "svelte" "typescript" "vercel" "vercel-deployment" "vite"];
    delete_branch_on_merge = false;
    ## gen-sitemap.yml pushes commits without declaring `permissions:`.
    workflow_permissions = "write";
  };
  "site" = {
    ## gen-sitemap.yml commits straight to the default branch.
    ruleset_bypass_actions = true;
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
