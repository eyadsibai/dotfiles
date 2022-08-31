{ lib
, config
, pkgs
, ...
}:
let
  inherit (lib) mkDefault mkIf mkOption types;
in
{
  programs.alacritty = {
    enable = false;
    settings = {
      window = {
        title = "Terminal";
        padding = { y = 5; };
        dimensions = {
          lines = 75;
          columns = 100;
        };
      };
      font = {
        # normal.family = "JetbrainsMono Nerd Font";
        size = 7.0;
      };
      window.opacity = 0.3;
      shell = { program = "${ pkgs.zsh }/bin/zsh"; };
      colors = {
        primary = {
          # background = "0x000000";
          # foreground = "0xEBEBEB";

          foreground = mkDefault "#${config.colorScheme.colors.base05}";
          background = mkDefault "#${config.colorScheme.colors.base00}";
        };
        cursor = {
          text = mkDefault "0xFF261E";
          cursor = mkDefault "0xFF261E";
        };
        normal = {
          black = mkDefault "0x0D0D0D";
          red = mkDefault "0xFF301B";
          green = mkDefault "0xA0E521";
          yellow = mkDefault "0xFFC620";
          blue = mkDefault "0x178AD1";
          magenta = mkDefault "0x9f7df5";
          cyan = mkDefault "0x21DEEF";
          white = mkDefault "0xEBEBEB";
        };
        bright = {
          black = mkDefault "0x6D7070";
          red = mkDefault "0xFF4352";
          green = mkDefault "0xB8E466";
          yellow = mkDefault "0xFFD750";
          blue = mkDefault "0x1BA6FA";
          magenta = mkDefault "0xB978EA";
          cyan = mkDefault "0x73FBF1";
          white = mkDefault "0xFEFEF8";
        };
      };
    };
  };
}
