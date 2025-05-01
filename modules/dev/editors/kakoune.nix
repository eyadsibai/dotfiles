{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.editors.kakoune;
in
{
  options.dev.editors.kakoune = {
    enable = lib.mkEnableOption "Kakoune editor";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.kakoune = {
          enable = true;
          # Add kakoune config if needed
        };
      };
    };
  };
}
