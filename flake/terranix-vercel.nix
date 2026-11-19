{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.qezta-vercel-json = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs;
      modules = [../terranix/qezta-vercel.nix];
    };
  };
}
