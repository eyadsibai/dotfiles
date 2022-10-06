# Fuzzing tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    gnumake
    gcc
  ];
  shellHook = "";
}
