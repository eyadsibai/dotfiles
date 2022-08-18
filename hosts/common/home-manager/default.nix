{ pkgs, ... }: {
  imports = [
    ./qutebrowser
    ./firefox
    ./git
    ./nix-index
    ./micro
    ./picom
    ./mpv
    ./newsboat
    # ./ngrok
    ./alacritty
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
  ];
}
