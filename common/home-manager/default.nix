{ pkgs, secrets, ... }: {

  imports = [
    ./qutebrowser
    ./firefox
    ./nix-index
    ./micro
    ./picom
    ./mpv
    ./newsboat
    ./ngrok
    ./networkmanager_dmenu
    ./kitty
    ./spotify
    ./rofi
    ./bitwarden
    ./polybar
    ./social
    ./accounts
    ./sxhkd
    ./zathura
    ./xcape
    ./feh
    ./unclutter
    ./flameshot
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
  ];
}
