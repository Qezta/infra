{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.qezta-github-json = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs;
      modules = [../terranix/qezta-github.nix];
    };
  };
}
