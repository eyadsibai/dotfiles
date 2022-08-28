{ inputs, pkgs, lib, config, ... }:
{

  nix = {
    extraOptions = "" + lib.optionalString (pkgs.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
    configureBuildUsers = true;
    settings.trusted-users = [
      "@admin"
    ];
  };

}
