{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.tools.devbox;
in
{
  options.dev.tools.devbox = {
    enable = lib.mkEnableOption "Devbox";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        home.packages = with pkgs; [
          devbox
        ];
      };
    };
  };
}
