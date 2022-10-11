{ pkgs, ... }: {
  home.packages = [ pkgs.sxiv ];
  xdg.configFile."sxiv"
    }
