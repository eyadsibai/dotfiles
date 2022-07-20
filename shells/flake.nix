{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:

    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        devShells = {
          # default = import ./shell.nix { inherit pkgs; };
          # cc = import ./cc.nix { inherit pkgs; };
          # go = import ./go.nix { inherit pkgs; };
          # grpc = import ./grpc.nix { inherit pkgs; };
          # java = import ./java.nix { inherit pkgs; };
          # node = import ./node.nix { inherit pkgs; };
          python = import ./python.nix { inherit pkgs; };
          # rust = import ./rust.nix { inherit pkgs; };
        };
      });

}
