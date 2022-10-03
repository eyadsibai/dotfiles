let



in
pkgs.mkShell
{
  buildInputs = [
    (pkgs.${python}.withPackages (ps: with ps; [ pip pyflakes isort ]))
    #  pkgs.nodePackages.pyright
    #  pkgs.nodePackages.prettier
    #  pkgs.docker
    #  pkgs.glpk
    pythonShell
    myPoetryEnv
  ];
  shellHook = "";
}




{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    dotfiles.url = "github:eyadsibai/dotfiles";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mach-nix = "github:DavHau/mach-nix";

  };

  outputs =
    { self
    , utils
    , dotfiles
    , nixpkgs
    , mach-nix
    }:
    let
      python = "python310";

      mach-nix-wrapper = import inputs.mach-nix { inherit pkgs python; };
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
              pythonShell-mach-nix
              #            defaultPackage
            ]
              #             ++ [ myPoetryEnv]
            ;
          };

          defaultPackage = with pkgs.poetry2nix;
            mkPoetryApplication {
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
