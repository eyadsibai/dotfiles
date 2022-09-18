# Host security tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    checksec
    chkrootkit
    linux-exploit-suggester
    lynis
    safety-cli
    tracee
    vulnix
  ];
  shellHook = "";
}
