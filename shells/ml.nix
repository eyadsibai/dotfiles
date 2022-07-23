{ pkgs, ... }:

with pkgs;
mkShell {
  buildInputs = [
    python310Packages.pip
    python310Packages.pip-tools
    opencv3
    python310Packages.pandas
    python310Packages.numpy
    python310Packages.scipy
    python310Packages.jupyter
    # python310Packages.pyjanitor

  ];
  shellHook = "";
}
