{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    adreaper
    certipy
    enum4linux
    enum4linux-ng
    erosmb
    evil-winrm
    go365
    gomapenum
    kerbrute
    nbtscanner
    offensive-azure
    python3Packages.pypykatz
    smbscan
  ];
  shellHook = "";
}
