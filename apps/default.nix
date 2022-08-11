{ pkgs, ... }: {
  imports = [
    ./browsers.nix
    ./email_cal_rss.nix
    ./social.nix
    ./media.nix
    ./office.nix
    ./services.nix
    ./development.nix
    ./terminal/default.nix
    ./system.nix
    ./custom_config/default.nix
  ];
}
