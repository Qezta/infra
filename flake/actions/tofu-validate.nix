## `tofu validate` for every stack, straight from the terranix output. Needs no
## credentials or state (-backend=false), so unlike tofu-plan it runs on every
## PR and catches schema errors against the pinned provider versions.
_: let
  pinned = {
    checkout = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1"; # v7.0.1
    nixInstall = "nixbuild/nix-quick-install-action@9f63be77f412a248c9d9a65a4c82cf066cdf8f0c"; # v35
    nixCache = "DeterminateSystems/magic-nix-cache-action@84c0677f58dcedf3b91f8223ce36a9ea5b3c84b7"; # v15
  };
  paths = ["terranix/**" "data/**" "orgs/**" "dns/**" "vercel/**" "huggingface/**" "flake.lock" "flake/terranix*.nix" "flake/actions/tofu-validate.nix"];
in {
  flake.actions-nix.workflows.".github/workflows/tofu-validate.yml" = {
    name = "tofu validate";
    on = {
      pull_request = {inherit paths;};
      push = {
        branches = ["main"];
        inherit paths;
      };
      workflow_dispatch = {};
    };
    permissions.contents = "read";
    jobs.validate = {
      strategy = {
        fail-fast = false;
        matrix.stack = [
          {
            package = "qezta-github-json";
            dir = "orgs/Qezta";
          }
          {
            package = "qezta-dns-json";
            dir = "dns/qezta.com";
          }
          {
            package = "qezta-vercel-json";
            dir = "vercel/Qezta";
          }
          {
            package = "qezta-huggingface-json";
            dir = "huggingface/Qezta";
          }
        ];
      };
      steps = [
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
        {
          name = "Validate \${{ matrix.stack.dir }}";
          ## A scratch copy keeps the committed .terraform.lock.hcl authoritative:
          ## init must resolve exactly the providers it pins.
          run = ''
            set -euo pipefail
            work="$RUNNER_TEMP/validate"
            mkdir -p "$work"
            nix build --no-link --print-out-paths '.#''${{ matrix.stack.package }}' | xargs cat > "$work/main.tf.json"
            cp '${"$"}{{ matrix.stack.dir }}/.terraform.lock.hcl' "$work/"
            nix develop -c tofu -chdir="$work" init -backend=false -input=false -lockfile=readonly
            nix develop -c tofu -chdir="$work" validate
          '';
        }
      ];
    };
  };
}
