{pkgs ? import <nixpkgs> {}, ...}:
with pkgs;
  mkShell {
    buildInputs = [
      drill
      cassowary
      ddosify
      siege
      tsung
      vegeta
    ];
    shellHook = "";
  }
