## Qezta's Hugging Face organization (huggingface.co/Qezta).
##
## Model repositories go through the m11s-io/huggingface provider, which manages
## a repo's identity and visibility only (no files, cards or weights). The org
## card is a Space, which that provider can't model, so it's pushed with the
## `hf` CLI from a terraform_data resource whenever huggingface/org-card/ changes.
##
## Token: HF_TOKEN, decrypted by huggingface/Qezta/terragrunt.hcl from
## Qezta/secrets (forge/huggingface/tofu.age). It needs write access to the
## Qezta org.
{lib, ...}: let
  namespace = "Qezta";

  ## Model repositories. `existing = true` adopts a repo that's already on the
  ## Hub (import), otherwise it's created. Destroy always retains the repo.
  ##   my-model = { private = true; existing = false; };
  models = {};

  card = ../huggingface/org-card;
in {
  terraform.required_version = ">= 1.11";
  terraform.required_providers.huggingface = {
    source = "registry.terraform.io/m11s-io/huggingface";
    version = "= 0.1.0";
  };
  provider.huggingface = {};

  resource = {
    huggingface_repository =
      lib.mapAttrs (name: m: {
        inherit namespace name;
        private = m.private or true;
        deletion_policy = "retain";
        lifecycle.prevent_destroy = true;
      })
      models;

    ## The org card: huggingface.co/spaces/Qezta/README renders on the org page.
    ## Re-runs only when the card's content changes (its store path is a content
    ## hash). Destroying this resource leaves the Space in place.
    terraform_data.org_card = {
      triggers_replace = "${card}";
      provisioner.local-exec = {
        working_dir = "${card}";
        command = ''
          set -eu
          hf repos create ${namespace}/README --type space --space-sdk static --public --exist-ok
          hf upload ${namespace}/README . . --repo-type space --commit-message "chore: sync org card from Qezta/infra"
        '';
        interpreter = ["sh" "-c"];
      };
    };
  };

  import = lib.mapAttrsToList (name: _: {
    to = "huggingface_repository.${name}";
    id = "model/${namespace}/${name}";
  }) (lib.filterAttrs (_: m: m.existing or true) models);

  output.org_card_url.value = "https://huggingface.co/${namespace}";
}
