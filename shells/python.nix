{ pkgs, ... }:

with pkgs;
mkShell {
  buildInputs = with python310Packages; [ pip pip-tools black flake8 ];
  shellHook = "";
}
