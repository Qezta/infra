_: {
  locals.repos = {
    ".github" = {
      description = "Qezta org profile";
      visibility = "public";
      topics = ["organization-profile" "profile" "qezta"];
      delete_branch_on_merge = false;
    };
    "divit" = {
      description = "divit.qezta.com — personal portfolio with Gemini-powered RAG chatbot";
      visibility = "public";
      topics = ["gemini" "personal-website" "portfolio" "rag" "svelte" "qezta"];
      delete_branch_on_merge = false;
    };
    "infra" = {
      description = "Terraform infrastructure configuration for Qezta";
      visibility = "public";
      topics = ["cloudflare" "dns" "infrastructure" "nix" "spaceship" "terraform" "terranix" "qezta"];
      delete_branch_on_merge = false;
    };
    "qezta-website" = {
      description = "Qezta Website";
      homepage_url = "https://www.Qezta.com";
      visibility = "public";
      topics = ["flake-parts" "nix" "personal-website" "svelte" "typescript" "vercel" "vercel-deployment" "vite" "qezta"];
      delete_branch_on_merge = false;
    };
    "site" = {
      description = "qezta.com — marketing site for Qezta";
      visibility = "public";
      topics = ["marketing" "personal-website" "svelte" "website" "qezta"];
      delete_branch_on_merge = false;
    };
    "ssh" = {
      description = "ssh divit@qezta.com — SSH terminal portfolio mirroring divit.qezta.com, built on wish + Bubble Tea";
      visibility = "public";
      topics = ["bubbletea" "go" "portfolio" "ssh" "tui" "wish" "qezta"];
      delete_branch_on_merge = false;
    };
    "ui" = {
      description = "Shared Svelte component library and design system for Qezta org sub-products";
      visibility = "public";
      topics = ["component-library" "design-system" "svelte" "typescript" "qezta"];
      delete_branch_on_merge = false;
    };
    "secrets" = {
      description = "Encrypted secrets for Qezta infrastructure and CI";
      visibility = "private";
      topics = ["agenix" "infrastructure" "nix" "secrets" "qezta"];
      delete_branch_on_merge = false;
    };
  };

  locals.protected_branches = {};
}
