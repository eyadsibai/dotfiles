{ pkgs, ... }:

with pkgs;
mkShell {
  buildInputs = with python310Packages; [
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
    # pytorch-metric-learning
    # pyjanitor
    # shap
  ] ++ [
    dvc
    tensorflow-lite
    vowpal-wabbit
    opencv3
  ];
  shellHook = "";
}
