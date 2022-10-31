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

  profile = ''
    set -e
    virtualenv venv
    source venv/bin/activate

    set +e

  '';
  # then pip install packages needed to work temporarily with.

}).env
