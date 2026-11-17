{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.qezta-dns-json = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs;
      modules = [../terranix/qezta-dns.nix];
    };
  };
}
