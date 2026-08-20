{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.qezta-repositories-json = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs;
      modules = [../terranix/qezta-repositories.nix];
    };
  };
}
