{ lib, pkgs, ... }:
with lib;
with lib.my;
rec {
  # default = import ../shell.nix { inherit pkgs; };
  python = import ./python { inherit pkgs; };
  cc = import ./cc { inherit pkgs; };
  
}
