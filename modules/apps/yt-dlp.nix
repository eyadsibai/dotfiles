{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.yt-dlp;
in
{
  options.apps.yt-dlp = {
    enable = lib.mkEnableOption "yt-dlp video downloader";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.yt-dlp = {
          enable = true;
          # Add config if needed
        };
      };
    };
  };
}
