{ pkgs, ... }:
# TODO https://nixos.wiki/wiki/Workgroup:DataScience
with pkgs;
mkShell {
  buildInputs = with python310Packages;
    [
      pip
      pip-tools
      pandas
      numpy
      scipy
      jupyter
      ipython
      thinc
      vowpalwabbit
      imgaug
      matplotlib
      mlflow
      tensorflow
      pytorch
      pytorch-lightning
      pymc3
      videocr
      mlrose
      tesseract5
      # pytorch-metric-learning
      # pyjanitor
      shap
    ] ++ [ dvc tensorflow-lite vowpal-wabbit opencv3 jax jaxlib ];
  shellHook = "";
}
