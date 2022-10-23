# Fuzzing tools
{ pkgs ? import <nixpkgs> { }, ... }:
let
  python = "python310";
in
(pkgs.buildFHSUserEnv {
  name = "pipzone";
  targetPkgs = pkgs: (with pkgs; [
    python310
    virtualenv
    python310Packages.pip
    # ${python}.virtualenv
    # cudaPackages.cudatoolkit_11
  ]);
  runScript = "bash";
}).env

# then run virtualenv venv
# then run source venv/bin/activate
# then pip install packages needed to work temporarily with.


