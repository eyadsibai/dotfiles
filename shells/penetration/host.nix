# Host security tools

{ pkgs ? import <nixpkgs> { }, ... }:

{
  environment.systemPackages = with pkgs; [
    checksec
    chkrootkit
    linux-exploit-suggester
    lynis
    safety-cli
    tracee
    vulnix
  ];
}
