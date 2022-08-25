{ pkgs
, ...
}:
{
  imports = [
    ./email_cal_rss.nix
    ./media.nix
    ./office.nix
    ./services.nix
    ./development.nix
    ./terminal
    ./system.nix
  ];

  # wm = ./wm;
}
