{ pkgs, ... }: {
  home.packages = [ pkgs.calcurse ];
  xdg.homeFile.".calcurse/conf".source = ./conf;
  xdg.homeFile.".calcurse/keys".source = ./keys;
}
