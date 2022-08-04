{ pkgs, ... }:
with pkgs;
mkShell {

  buildInputs = [
    cantoolz
    chipsec
    esptool
    extrude
    hachoir
    nrfutil
    tytools
    python3Packages.angr
    python3Packages.angrop
    python3Packages.can
    python3Packages.pyi2cflash
    python3Packages.pyspiflash
    routersploit
  ];
  shellHook = "";
}
    