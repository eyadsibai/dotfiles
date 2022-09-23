# Code analysing tools, incl. search for secrets and alike in code
{ pkgs ? import <nixpkgs> { }, ... }: with pkgs;
mkShell
{
  buildInputs = [
    cargo-audit
    credential-detector
    detect-secrets
    git-secret
    gitjacker
    gitleaks
    gitls
    gokart
    gosca
    osv-detector
    pip-audit
    pip-check
    python310Packages.safety
    secretscanner
    shhgit
    skjold
    skjold
    trufflehog
    whispers
  ];
  shellHook = "";
}
