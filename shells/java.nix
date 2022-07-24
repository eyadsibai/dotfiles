{ pkgs ? import <nixpkgs> { } }:

with pkgs;
mkShell {
  buildInputs = [ maven jre8 jdk8 ];
  shellHook = "";
}
