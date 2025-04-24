{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.carapace;
in
{
  options.shell.carapace = {
    enable = lib.mkEnableOption "Carapace completion";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}" = {
      programs.carapace = {
        enable = true;
        enableNushellIntegration = true; # Consider making these conditional
        enableZshIntegration = true;
        enableBashIntegration = true;
      };
    };
  };
}
