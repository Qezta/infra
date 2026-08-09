{inputs, ...}: {
  imports = [inputs.terranix.flakeModule];

  perSystem = {pkgs, ...}: {
    packages.terraform-json = inputs.terranix.lib.terranixConfiguration {
      inherit pkgs;
      modules = [../terranix/main.nix];
    };
  };
}
