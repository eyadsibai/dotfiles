{ pkgs, ... }:

with pkgs;
mkShell {
  buildInputs = [ python310Packages.pip python310Packages.pip-tools ];
  shellHook = "";
}
