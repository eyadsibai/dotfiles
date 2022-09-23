{
  description = "A basic flake for erlang project";
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

    in
    {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.bashInteractive
        ];

        buildInputs = with pkgs; [
          julia
        ];

        shellHook = ''
        '';
      };
    });
}
