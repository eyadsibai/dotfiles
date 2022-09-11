{ pkgs ? import <nixpkgs> { } }:
# TODO https://nixos.wiki/wiki/Workgroup:DataScience
with pkgs;
mkShell
{
  buildInputs = with python310Packages;
    [

      tensorflow
      pytorch
      pytorch-lightning

      tesseract5
      # pytorch-metric-learning

    ]
    ++ [
      dvc
      tensorflow-lite
      vowpal-wabbit
      opencv3
      jax
      jaxlib

    ];
  shellHook = "";
}
