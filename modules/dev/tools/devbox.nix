{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.tools.devbox;
in
{
  options.dev.tools.devbox = {
    enable = lib.mkEnableOption "Devbox";
  };

  config = lib.mkIf cfg.enable {
    # environment.systemPackages = with pkgs; [ devbox ]; # Moved to HM
    home-manager.users."${username}".home.packages = with pkgs; [
      devbox
    ];
  };
}
