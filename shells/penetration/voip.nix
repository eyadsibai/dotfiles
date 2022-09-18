{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    sipp
    sipsak
    sipvicious
    sngrep
  ];
  shellHook = "";
}
