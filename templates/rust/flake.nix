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

    in
    {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.bashInteractive
        ];

        buildInputs = with pkgs; [
          rustup
        ];
        shellHook = ''
          export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
          export CARGO_HOME="$XDG_DATA_HOME/cargo"
          export PATH="$CARGO_HOME/bin:$PATH"
        '';
      };
    });
}
