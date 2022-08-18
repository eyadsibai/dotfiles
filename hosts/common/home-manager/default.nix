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
    ./ngrok
    ./alacritty
    ./networkmanager_dmenu
    ./kitty
    ./spotify
    ./rofi
    ./bitwarden
    ./polybar
    ./social
    ./accounts
    ./sxhkd.nix
    ./zathura.nix
    ./xcape.nix
    ./feh.nix
    ./unclutter.nix
    ./flameshot.nix
    ./direnv
  ];
}
