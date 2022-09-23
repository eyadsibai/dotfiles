# Kubernetes infrastructure and Windows-related tools, incl. SMB
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    cfripper
    checkov
    kdigger
    kube-score
    kubeaudit
    kubescape
  ];
  shellHook = "";
}
