## Invariant tests over the generated OpenTofu JSON. Runs in the sandbox with no
## credentials or state, so it gates every PR even while tofu-plan is disabled.
{lib, ...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: let
    src = lib.fileset.toSource {
      root = ../.;
      fileset = ../tests;
    };
    python = pkgs.python3.withPackages (ps: [ps.pytest]);
  in {
    checks.terranix-invariants =
      pkgs.runCommand "qezta-terranix-invariants" {
        nativeBuildInputs = [python];
        QEZTA_DNS_JSON = config.packages.qezta-dns-json;
        QEZTA_GITHUB_JSON = config.packages.qezta-github-json;
        QEZTA_VERCEL_JSON = config.packages.qezta-vercel-json;
      } ''
        cd ${src}
        pytest -p no:cacheprovider -v tests
        touch $out
      '';
  };
}
