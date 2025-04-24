{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.tools.direnv;
in
{
  options.dev.tools.direnv = {
    enable = lib.mkEnableOption "direnv configuration";
  };

  config = lib.mkIf cfg.enable {
    # direnv package could be added here if not managed elsewhere
    # environment.systemPackages = with pkgs; [ direnv ];

    home-manager.users."${username}" = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
