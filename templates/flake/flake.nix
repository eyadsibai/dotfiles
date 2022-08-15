{
  description = "flake environment template";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";


  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;

          overlays = [ devshell.overlay ];
        };

      in
      {
        devShell = pkgs.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];

          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = [ ];
        };
      });
}
