{ inputs, pkgs, lib, config, ... }:
{

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
