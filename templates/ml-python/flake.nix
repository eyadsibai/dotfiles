{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    dotfiles.url = "github:eyadsibai/dotfiles";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self
    , flake-utils
    , dotfiles
    , nixpkgs
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      python = "python310";

      pkgs = nixpkgs.legacyPackages.${system};
      custom_pkgs = dotfiles.legacyPackages.${system};

      # myPoetryEnv = pkgs.poetry2nix.mkPoetryEnv {
      # projectDir = ./.;
      # python = pkgs."${python}";
      # preferWheels = true;
      # };
    in
    rec {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.bashInteractive
          pkgs.llvmPackages_9.llvm
        ];
        buildInputs = with pkgs; [
          python310Packages.poetry
          custom_pkgs.rgf
          custom_pkgs.fast-rgf
          custom_pkgs.libfm
          vowpal-wabbit
          #                    dvc
          opencv
          tesseract5
          # tensorflow-lite
          pre-commit
          # defaultPackage
        ]
          # ++ [ myPoetryEnv ]
        ;
      };

      defaultPackage = with pkgs.poetry2nix;
        mkPoetryApplication {
          projectDir = ./.;
          preferWheels = true;
        };


      defaultApp = flake-utils.lib.mkApp {
        drv = self.defaultPackage."${system}";
      };
    });
}
