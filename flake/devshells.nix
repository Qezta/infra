{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem = {pkgs, ...}: {
    devshells.default = {
      devshell = rec {
        name = "infra";
        motd = "{202}Welcome to {91}${name} {202}devshell!{reset} \n $(menu)";
        packages = lib.attrsets.attrValues {
          inherit (pkgs) alejandra gh nixd terraform;
        };
      };
    };
  };
}
