{ pkgs, secrets, ... }: {

  imports = [
    ./nix-index
    ./picom
    ./newsboat
    ./ngrok
    ./networkmanager_dmenu
    ./kitty
    ./spotify
    ./menu
    ./bitwarden
    ./polybar
    ./social
    ./accounts
    ./sxhkd
    ./zathura
    ./xcape
    ./unclutter
    ./direnv
    ./htop
    ./udiskie
    ./development.nix
    ./email_cal_rss.nix
    ./media.nix
    ./office.nix
    ./services.nix
    ./system.nix
    ./terminal
    ./discord.nix
    ./gtk
  ];
}
