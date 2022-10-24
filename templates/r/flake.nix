{
  description = "A basic flake for go project";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      RStudio-with-my-packages =
        pkgs.rstudioWrapper.override
          {
            packages = with pkgs.rPackages; [
              ggplot2
              dplyr
              xts
              rmarkdown
              knitr
              lubridate
              Robyn
              data_table
              simstudy
              Matrix
              RSQLite
              Rcpp
              SOAR
              biganalytics
              # bigmemory
              bigtabulate
              caret
              digest
              doMC
              dplyr
              e1071
              ff
              foreach
              gbm
              ggmap
              ggplot2
              glmnet
              leaflet
              lpSolve
              mapview
              mlr3
              nnet
              lidR
              ncdf4
              jsonlite
              geonames
              igraph
              rnaturalearth
              RNetCDF
              classInt
              randomForest
              randtoolbox
              raster
              rbenchmark
              rgdal
              rgl
              SimMultiCorrData
              simstudy
              sf
              sp
              spdep
              sqldf
              stringi
              tau
              tidyverse
              tm
              xgboost
              xts
              zoo
              digest
            ];
          };

    in
    {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.bashInteractive
        ];

        buildInputs = with pkgs; [
          RStudio-with-my-packages
          pkgs.R
        ];
        shellHook = ''
        '';
        MANPATH = "${pkgs.R.outPath}/share/man";

      };
    });
}
