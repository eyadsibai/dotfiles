{
  description = "A basic flake for java project";
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
          maven
          jdk11
          clojure
          leiningen
          clj-kondo
          #jdtls
        ];
        shellHook = ''
          export JAVA_HOME=${pkgs.jdk11}
          PATH="${pkgs.jdk11}/bin:$PATH"
        '';
      };
    });
}
