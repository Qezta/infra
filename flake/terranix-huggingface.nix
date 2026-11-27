{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.qezta-huggingface-json = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs;
      modules = [../terranix/qezta-huggingface.nix];
    };
  };
}
