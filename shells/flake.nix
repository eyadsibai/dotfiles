{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";

      # The main branch follows the "canary" channel of the Android SDK
      # repository. Use another android-nixpkgs branch to explicitly
      # track an SDK release channel.
      #
      # url = "github:tadfisher/android-nixpkgs/stable";
      # url = "github:tadfisher/android-nixpkgs/beta";
      # url = "github:tadfisher/android-nixpkgs/preview";
      # url = "github:tadfisher/android-nixpkgs/canary";

      # If you have nixpkgs as an input, this will replace the "nixpkgs" input
      # for the "android" flake.
      #
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs, ... }:

    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        devShells = {
          default = import ./shell.nix { inherit pkgs; };
          cc = import ./cc.nix { inherit pkgs; };
          go = import ./go.nix { inherit pkgs; };
          java = import ./java.nix { inherit pkgs; };
          node = import ./node.nix { inherit pkgs; };
          python = import ./python.nix { inherit pkgs; };
          rust = import ./rust.nix { inherit pkgs; };
          ml = import ./ml.nix { inherit pkgs; };
          # android = import ./android.nix {inherit pkgs android-nixpkgs ; };
        };
      });

}
