# Terminal tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    cutecom
    minicom
    picocom
    socat
    x3270
  ];
  shellHook = "";
}
