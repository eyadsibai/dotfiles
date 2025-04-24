{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.editors.kakoune;
in
{
  options.dev.editors.kakoune = {
    enable = lib.mkEnableOption "Kakoune editor";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}".programs.kakoune = {
      enable = true;
      # Add kakoune config if needed
    };
  };
}
