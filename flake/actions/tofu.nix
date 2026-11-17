## OpenTofu CI: plan on pull requests (posted as a comment), apply on main only
## after approval through the `infra-apply` environment. Both stay off until
## the repository variable REMOTE_STATE_ENABLED is "true": without remote
## state, CI has nothing to plan against (see docs/remote-state.md).
_: let
  pinned = {
    checkout = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1"; # v7.0.1
    nixInstall = "nixbuild/nix-quick-install-action@9f63be77f412a248c9d9a65a4c82cf066cdf8f0c"; # v35
    nixCache = "DeterminateSystems/magic-nix-cache-action@84c0677f58dcedf3b91f8223ce36a9ea5b3c84b7"; # v15
  };
  paths = ["root.hcl" "orgs/**" "terranix/**" "data/**" "flake.lock"];
  ## Only orgs/Qezta runs in CI for now; dns/qezta.com needs Spaceship
  ## credentials and is applied by hand.
  env = {
    TOFU_REMOTE_STATE = "true";
    CLOUDFLARE_ACCOUNT_ID = "\${{ vars.CLOUDFLARE_ACCOUNT_ID }}";
    AWS_ACCESS_KEY_ID = "\${{ secrets.R2_ACCESS_KEY_ID }}";
    AWS_SECRET_ACCESS_KEY = "\${{ secrets.R2_SECRET_ACCESS_KEY }}";
    ## OpenTofu state encryption config (HCL), kept entirely in a secret.
    TF_ENCRYPTION = "\${{ secrets.TF_ENCRYPTION }}";
    GITHUB_TOKEN_QEZTA = "\${{ secrets.QEZTA_INFRA_TOKEN }}";
  };
  setup = [
    {
      name = "Checkout";
      uses = pinned.checkout;
      "with".persist-credentials = false;
    }
    {
      name = "Install Nix";
      uses = pinned.nixInstall;
    }
    {
      name = "Nix cache";
      uses = pinned.nixCache;
    }
  ];
in {
  flake.actions-nix.workflows = {
    ".github/workflows/tofu-plan.yml" = {
      name = "tofu plan";
      on.pull_request.paths = paths;
      permissions = {
        contents = "read";
        pull-requests = "write";
      };
      jobs.plan = {
        "if" = "vars.REMOTE_STATE_ENABLED == 'true'";
        inherit env;
        steps =
          setup
          ++ [
            {
              name = "Plan";
              working-directory = "orgs/Qezta";
              run = ''
                set -o pipefail
                nix develop ../.. -c terragrunt plan -no-color -lock=false 2>&1 | tee plan.txt
              '';
            }
            {
              name = "Comment plan";
              "if" = "always()";
              working-directory = "orgs/Qezta";
              env.GH_TOKEN = "\${{ github.token }}";
              run = ''
                {
                  echo "### \`tofu plan\` (orgs/Qezta)"
                  echo '```'
                  tail -c 60000 plan.txt
                  echo '```'
                } > comment.md
                gh pr comment "''${{ github.event.pull_request.number }}" --body-file comment.md
              '';
            }
          ];
      };
    };

    ".github/workflows/tofu-apply.yml" = {
      name = "tofu apply";
      on = {
        push = {
          branches = ["main"];
          inherit paths;
        };
        workflow_dispatch = {};
      };
      permissions.contents = "read";
      concurrency.group = "tofu-apply";
      jobs.apply = {
        "if" = "vars.REMOTE_STATE_ENABLED == 'true'";
        ## Required reviewers on this environment approve every apply.
        environment = "infra-apply";
        inherit env;
        steps =
          setup
          ++ [
            {
              name = "Apply";
              working-directory = "orgs/Qezta";
              run = "nix develop ../.. -c terragrunt apply -no-color -auto-approve";
            }
          ];
      };
    };
  };
}
