{
  description = "A basic flake for conda project";
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
          conda
        ];
        shellHook = ''
          #export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
          #export CARGO_HOME="$XDG_DATA_HOME/cargo"
          #export PATH="$CARGO_HOME/bin:$PATH"
          echo "run this to launch ..."
          CMD="conda-shell then conda-install -u"
          echo $CMD

        '';
      };
    });
}
