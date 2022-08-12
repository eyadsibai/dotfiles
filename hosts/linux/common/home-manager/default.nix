{pkgs, ...}: {
  imports = [
    ./sxhkd.nix
    ./zathura.nix
    ./xcape.nix
    ./feh.nix
    ./unclutter.nix
    ./flameshot.nix
  ];
}
