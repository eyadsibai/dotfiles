# Container analysing tools
{ pkgs ? import <nixpkgs> { }, ... }:

with pkgs;
mkShell
{
  buildInputs = [
    cdk-go
    clair
    cliam
    cloudlist
    dive
    dockle
    fwanalyzer
    grype
    trivy
  ];
  shellHook = "";
}
