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
    python310Packages.thinc

    vowpal-wabbit
    python310Packages.vowpalwabbit
    python310Packages.imgaug
    python310Packages.matplotlib
    python310Packages.mlflow
    tensorflow-lite
    python310Packages.tensorflow
    #python310Packages.shap
    python310Packages.pytorch
    python310Packages.pytorch-lightning
    # python310Packages.pytorch-metric-learning
    dvc
    # python310Packages.pyjanitor

  ];
  shellHook = "";
}
