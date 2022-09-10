{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    dotfiles.url = "github:eyadsibai/dotfiles";
  };

  outputs =
    { self
    , utils
    , dotfiles
    ,
    }:
    let
      out = system:
        let
          pkgs = dotfiles.legacyPackages.${system};

        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              python3Packages.poetry
              rgf
              fast-rgf
            ];
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
