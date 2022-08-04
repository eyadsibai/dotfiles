{ pkgs, ... }:
with pkgs;
mkShell {

  buildInputs = [
    authoscope
    bruteforce-luks
    brutespray
    crunch
    hashcat
    hashcat-utils
    hashdeep
    john
    medusa
    nasty
    ncrack
    nth
    phrasendrescher
    python3Packages.patator
    thc-hydra
    truecrack
  ];
  shellHook = "";
}
    