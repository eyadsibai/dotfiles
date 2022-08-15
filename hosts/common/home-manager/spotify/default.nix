{ pkgs, ... }: {
  home.packages = [
    pkgs.spotify-tui
    pkgs.spotify
  ];
  services.spotifyd.enable = true;

}
