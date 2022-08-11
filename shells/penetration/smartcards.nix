{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell {
  buildInputs = [
    cardpeek
    libfreefare
    mfcuk
    mfoc
    python3Packages.emv
  ];
  shellHook = "";
}
