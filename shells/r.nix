{pkgs ? import <nixpkgs> {}}: let
  RStudio-with-my-packages = pkgs.rstudioWrapper.override {
    packages = with pkgs.rPackages; [
      ggplot2
      dplyr
      xts
      rmarkdown
      knitr
      lubridate
      Robyn
    ];
  };
in
  pkgs.mkShell {buildInputs = with pkgs; [RStudio-with-my-packages];}
