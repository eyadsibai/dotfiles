# Various tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    badchars
    changetower
    # deepsea
    doona
    honeytrap
    jwt-cli
    nmap-formatter
    pwntools
    python3Packages.pytenable
  ];
  shellHook = "";
}
