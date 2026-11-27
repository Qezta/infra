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
##
## Drift: model repos are refreshed by the provider like any resource. The org
## card has no provider, so data.external.org_card_state runs
## scripts/org_card_state.py on every plan. It compares the Space's file tree
## (git blob ids) with huggingface/org-card and returns "in_sync", "missing"
## or "drift:<n> files differ". That state is part of the card's trigger, so a
## Hub-side edit, a stray file or a deleted Space plans a re-push. After a
## heal the next plan re-runs once more (a no-op: unchanged uploads are
## skipped) to record "in_sync", then stays clean.
{
  lib,
  pkgs,
  ...
}: let
  namespace = "Qezta";

  ## Model repositories. `existing = true` adopts a repo that's already on the
  ## Hub (import), otherwise it's created. Destroy always retains the repo.
  ##   my-model = { private = true; existing = false; };
  models = {};

  card = ../huggingface/org-card;
  cardRepo = "${namespace}/README";
  hfPython = pkgs.python3.withPackages (ps: [ps.huggingface-hub]);
in {
  terraform.required_version = ">= 1.11";
  terraform.required_providers = {
    huggingface = {
      source = "registry.terraform.io/m11s-io/huggingface";
      version = "= 0.1.0";
    };
    external = {
      source = "hashicorp/external";
      version = "~> 2.3";
    };
  };
  provider.huggingface = {};

  data.external.org_card_state = {
    program = ["${pkgs.python3}/bin/python3" "${../huggingface/scripts/org_card_state.py}"];
    query = {
      repo = cardRepo;
      card = "${card}";
    };
  };

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
    ## Replaced (so re-pushed) when the card or the Space's drift state
    ## changes. Destroying it leaves the Space in place.
    terraform_data.org_card = {
      triggers_replace = {
        card = "${card}";
        remote = "\${data.external.org_card_state.result.state}";
      };
      provisioner.local-exec.command = "${hfPython}/bin/python3 ${../huggingface/scripts/org_card_push.py} ${cardRepo} ${card}";
    };
  };

  import = lib.mapAttrsToList (name: _: {
    to = "huggingface_repository.${name}";
    id = "model/${namespace}/${name}";
  }) (lib.filterAttrs (_: m: m.existing or true) models);

  output.org_card_url.value = "https://huggingface.co/${namespace}";
}
