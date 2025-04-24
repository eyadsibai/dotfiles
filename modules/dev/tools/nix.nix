{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.tools.nix;
in
{
  options.dev.tools.nix = {
    enable = lib.mkEnableOption "Nix development tools (nixd, nil)";
  };

  config = lib.mkIf cfg.enable {
    # environment.systemPackages = with pkgs; [ nixd nil ]; # Moved to HM
    home-manager.users."${username}".home.packages = with pkgs; [
      nixd
      nil
    ];
  };
}
