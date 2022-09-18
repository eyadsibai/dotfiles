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
        ];
        shellHook = ''
        '';
      };
    });
}
