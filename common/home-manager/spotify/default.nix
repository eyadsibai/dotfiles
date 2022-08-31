{ pkgs, ... }: {
  home.packages = [
    pkgs.spotify-tui
    pkgs.spotify
    pkgs.spicetify-cli
  ];
  services.spotifyd.enable = true;

}
