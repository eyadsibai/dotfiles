{ pkgs ? import <nixpkgs> { } }:
let
  fhs = pkgs.buildFHSUserEnv {
    name = "my-fhs-environment";

    targetPkgs = _: [
      pkgs.micromamba
    ];

    profile = ''
      set -e
      eval "$(micromamba shell hook -s bash)"
      export MAMBA_ROOT_PREFIX=${builtins.getEnv "PWD"}/.mamba
      micromamba create -q -n my-mamba-environment
      micromamba activate my-mamba-environment
      micromamba install --yes -f conda-requirements.txt -c conda-forge
      set +e
    '';
  };
in
fhs.env
