{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    dotfiles.url = "github:eyadsibai/dotfiles";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mach-nix.url = "github:DavHau/mach-nix";

  };

  outputs =
    { self
    , flake-utils
    , dotfiles
    , nixpkgs
    , mach-nix
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      python = "python310";

      pkgs = nixpkgs.legacyPackages.${system};
      custom_pkgs = dotfiles.legacyPackages.${system};
      mach-nix-wrapper = import mach-nix { inherit pkgs python; };
      #  requirements = builtins.readFile ./requirements.txt;
      #  pythonShell = mach-nix-wrapper.mkPython { inherit requirements; };
      pythonShell-mach-nix =
        mach-nix-wrapper.mkPython
          {
            requirements = ''
               # pandas
              #  black
            '';
          };

      myPoetryEnv = pkgs.poetry2nix.mkPoetryEnv {
        projectDir = ./.;
        python = pkgs."${python}";
        preferWheels = true;
      };
    in
    rec {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
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
          # pythonShell-mach-nix
          #            defaultPackage
        ]
        ++ [ myPoetryEnv ]
        ;
      };

      defaultPackage = with pkgs.poetry2nix;
        mkPoetryApplication {
          projectDir = ./.;
          preferWheels = true;
        };


      # defaultApp = flake-utils.lib.mkApp {
      #   drv = self.defaultPackage."${system}";
      # };
    });
}
