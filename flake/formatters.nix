{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      settings.global.excludes = [".github/*"];
      flakeCheck = false;
      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        mdformat.enable = true;
        ## `tofu fmt` instead of the BSL-licensed terraform binary.
        terraform = {
          enable = true;
          package = pkgs.opentofu;
        };
      };
    };
  };
}
