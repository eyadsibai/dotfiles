{pkgs ? import <nixpkgs> {}, ...}:
with pkgs;
  mkShell {
    buildInputs = [
      bore-cli
      corkscrew
      hans
      chisel
      httptunnel
      iodine
      proxytunnel
      sish
      stunnel
      udptunnel
      wstunnel
    ];
    shellHook = "";
  }
