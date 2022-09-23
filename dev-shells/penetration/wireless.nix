{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    aircrack-ng
    airgeddon
    bully
    cowpatty
    horst
    kismet
    pixiewps
    reaverwps
    wavemon
    wifite2
  ];
  shellHook = "";
}
