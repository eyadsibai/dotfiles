{ pkgs
, ...
}:
{
  imports = [
    ./polybar.nix
    ./packages.nix
    ./i3.nix
  ];
}
