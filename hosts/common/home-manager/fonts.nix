{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  home.packages = with pkgs; [
    nerd-fonts.terminess-ttf

  ];


}
