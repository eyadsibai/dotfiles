{ pkgs
, ...
}:
{
  imports = [
    ./packages.nix
    ./i3.nix
  ];
}
