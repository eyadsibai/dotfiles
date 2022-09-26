{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    dotfiles.url = "github:eyadsibai/dotfiles";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  };

  outputs =
    { self
    , utils
    , dotfiles
    , nixpkgs
    }:
    let
      out = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          custom_pkgs = dotfiles.legacyPackages.${system};

        in
        rec {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              poetry
              custom_pkgs.rgf
              custom_pkgs.fast-rgf
              vowpal-wabbit
              dvc
              opencv
              tesseract5
              # tensorflow-lite
              pre-commit
              #            defaultPackage
            ]
              #             ++ [ defaultEnv]
            ;
          };

          defaultPackage = with pkgs.poetry2nix;
            mkPoetryApplication {
              projectDir = ./.;
              preferWheels = true;
            };

          defaultEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            preferWheels = true;
          };

          defaultApp = utils.lib.mkApp {
            drv = self.defaultPackage."${system}";
          };
        };
    in
    with utils.lib; eachSystem defaultSystems out;
}
