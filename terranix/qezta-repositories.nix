{
  ".github" = {
    description = "Qezta org profile";
    visibility = "public";
    topics = ["organization-profile" "profile" "qezta"];
    delete_branch_on_merge = false;
  };
  "divit" = {
    description = "divit.qezta.com — personal portfolio with Gemini-powered RAG chatbot";
    visibility = "public";
    topics = ["gemini" "personal-website" "portfolio" "qezta" "rag" "svelte"];
    delete_branch_on_merge = false;
  };
  "infra" = {
    description = "Terraform infrastructure configuration for Qezta";
    visibility = "public";
    topics = ["cloudflare" "dns" "infrastructure" "nix" "qezta" "spaceship" "terraform" "terranix"];
    delete_branch_on_merge = false;
  };
  "qezta-website" = {
    description = "Qezta Website";
    homepage_url = "https://www.Qezta.com";
    visibility = "public";
    topics = ["flake-parts" "nix" "personal-website" "qezta" "svelte" "typescript" "vercel" "vercel-deployment" "vite"];
    delete_branch_on_merge = false;
  };
  "site" = {
    description = "qezta.com — marketing site for Qezta";
    visibility = "public";
    topics = ["marketing" "personal-website" "qezta" "svelte" "website"];
    delete_branch_on_merge = false;
  };
  "ssh" = {
    description = "ssh divit@qezta.com — SSH terminal portfolio mirroring divit.qezta.com, built on wish + Bubble Tea";
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
  };
}
