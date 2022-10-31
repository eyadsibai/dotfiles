{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    dotfiles.url = "github:eyadsibai/dotfiles";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self
    , flake-utils
    , dotfiles
    , nixpkgs
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        python = "python310";

        pkgs = nixpkgs.legacyPackages.${system};
        custom_pkgs = dotfiles.legacyPackages.${system};

        libPaths = pkgs.lib.makeLibraryPath [
          pkgs.libstdcxx5
          pkgs.openblasCompat
          pkgs.lapack-reference
          pkgs.zlib
          pkgs.stdenv.cc.cc.lib
        ];

        myPoetryEnv = pkgs.poetry2nix.mkPoetryEnv {
          projectDir = ./.;
          python = pkgs."${python}";
          preferWheels = true;
        };

        defaultPackage = with pkgs.poetry2nix;
          mkPoetryApplication {
            projectDir = ./.;
            preferWheels = true;
          };
      in
      rec {

        # should I replace it with pkgs.buildFHSUserEnv
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bashInteractive
            pkgs.llvmPackages_9.llvm
            pkgs.libclang
          ];

          buildInputs = with pkgs; [
            python310Packages.poetry
            custom_pkgs.rgf
            custom_pkgs.fast-rgf
            custom_pkgs.libfm
            vowpal-wabbit
            #                    dvc
            opencv
            tesseract5
            # tensorflow-lite
            pre-commit
            # defaultPackage
          ]
            # ++ [ myPoetryEnv ]
          ;

          shellHook =
            (builtins.concatStringsSep "\n"
              [

                ''
                  export LIBCLANG_PATH="${pkgs.libclang}/lib";
                  export LD_LIBRARY_PATH="${libPaths}:${pkgs.stdenv.cc.cc.lib}/lib64:$LD_LIBRARY_PATH}"
                ''

                (pkgs.lib.optionalString (system == "x86_64-linux") ''
                  export LD_LIBRARY_PATH=${pkgs.llvmPackages_9.llvm}/lib:$LD_LIBRARY_PATH
                '')

                (pkgs.lib.optionalString (system == "x86_64-darwin" || system == "aarch64-darwin") ''
                  export DYLD_LIBRARY_PATH=${pkgs.llvmPackages_9.llvm}/lib:$DYLD_LIBRARY_PATH
                  export CC=/usr/local/opt/llvm/bin/clang
                  export CXX=/usr/local/opt/llvm/bin/clang++
                  export LDFLAGS="-L/usr/local/opt/llvm/lib"
                  export CPPFLAGS="-I/usr/local/opt/llvm/include"
                '')
              ]);
        };

        defaultApp = flake-utils.lib.mkApp {
          drv = self.defaultPackage."${system}";
        };
      });
}
