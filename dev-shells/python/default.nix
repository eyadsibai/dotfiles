{ pkgs ? import <nixpkgs> { }, ... }:
let
  python = "python310";
in
with pkgs;
mkShell
{
  nativeBuildInputs = [ pkgs.bashInteractive ];
  buildInputs = [
    pkgs."${python}Packages".jupyter
    pkgs."${python}Packages".pandas
    pkgs."${python}Packages".matplotlib
    pkgs."${python}Packages".scikit-learn
    pkgs."${python}Packages".watermark
  ];
  shellHook = "";
}
