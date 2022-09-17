{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      buildNodejs = pkgs.callPackage (nixpkgs + "/pkgs/development/web/nodejs/nodejs.nix") { python = pkgs.python39; };
      nodejs-16 = buildNodejs {
        enableNpm = true;
        version = "16.0.0";
        sha256 = "sha256-R8uQER6MPcQtxThGR4lBU1Tw2TNYf8if/3H5vYFqqgI=";
      };

      nodejs-current = pkgs.nodejs-16_x;
    in
    {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.bashInteractive
        ];

        buildInputs = [
          nodejs-current
          #pkgs.prisma-engines
          pkgs.nodePackages.prisma
          (pkgs.yarn.override { nodejs = nodejs-current; })
        ];
        shellHook = ''
          # alias rw = "yarn redwood"
           export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
           export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
           export NPM_CACHE_PREFIX="$XDG_CACHE_HOME/npm"
           export PATH="$(yarn global bin):$PATH"
          export PRISMA_MIGRATION_ENGINE_BINARY="${pkgs.prisma-engines}/bin/migration-engine"
          export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
          export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
          export PRISMA_INTROSPECTION_ENGINE_BINARY="${pkgs.prisma-engines}/bin/introspection-engine"
          export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
        '';
      };
    });
}
