{ inputs, pkgs, lib, config, ... }:
{

  imports = [
    ../../../common/nix.nix
  ];

  nix = {
    extra-platforms = lib.lists.optionals (pkgs.system == "aarch64-darwin") [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    configureBuildUsers = true;
    trusted-users = [
      "@admin"
    ];
  };

}
