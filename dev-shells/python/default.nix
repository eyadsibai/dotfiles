# Fuzzing tools
{ pkgs ? import <nixpkgs> { }, ... }:
let
  python = "python310";
in
with pkgs;
mkShell
{
  nativeBuildInputs = [ pkgs.bashInteractive ];
  buildInputs = with pkgs.${python}; [
    jupyter
    pandas
    matplotlib
    scikit-learn
    watermark
  ];
  shellHook = "";
}
