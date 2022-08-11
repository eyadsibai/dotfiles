# Container analysing tools
{ pkgs ? import <nixpkgs> { }, ... }: {
  environment.systemPackages = with pkgs; [
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
}
