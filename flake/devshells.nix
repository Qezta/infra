{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.devshell.flakeModule];

  perSystem = {pkgs, ...}: {
    devshells.default = {
      devshell = {
        name = "infra";
        packages = lib.attrsets.attrValues {
          inherit (pkgs) alejandra gh terraform;
        };
      };
    };
  };
}
