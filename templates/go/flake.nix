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
          go
          gopls
          protoc-gen-go
          protoc-gen-go-grpc
        ];
        shellHook = ''
          export GO111MODULE=on
          export GOPATH=$XDG_DATA_HOME/go
          export PATH=$GOPATH/bin:$PATH
        '';
      };
    });
}
