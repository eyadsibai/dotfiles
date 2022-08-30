{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs darwin;
  inherit (self) outputs;
  inherit (darwin.lib) darwinSystem;
  inherit (home-manager.lib) homeManagerConfiguration;

  inherit (builtins) elemAt match any mapAttrs attrValues attrNames listToAttrs;
  inherit (nixpkgs.lib) nixosSystem filterAttrs genAttrs mapAttrs' mapAttrsToList lists regularOf stdenv optional;
in
rec {
  # Applies a function to a attrset's names, while keeping the values
  mapAttrNames = f: mapAttrs' (name: value: { name = f name; inherit value; });

  has = element: any (x: x == element);

  mkNixOsSystem =
    { hostname
    , pkgs
    , user
      # , system
    , is-wsl ? false
    }:
    nixosSystem {
      inherit pkgs;
      specialArgs = {
        inherit inputs outputs hostname user;
      };
      modules = attrValues (import ../modules/nixos)
        ++ (optional is-wsl inputs.nixos-wsl.nixosModules.wsl)
        ++ [
        ../hosts/${hostname}
        inputs.nixpkgs.nixosModules.notDetected
        inputs.nur.nixosModules.nur
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            useGlobalPkgs = true;
            users.${user} = {
              imports = [ ../hosts/${hostname}/home-manager ]
                ++ attrValues (import ../modules/home-manager);
            };
            extraSpecialArgs = { inherit inputs outputs; };
            backupFileExtension = "backup";
          };
        }
      ];
    };

  mkDarwinSystem =
    { hostname
    , pkgs
    , user
    }:
    darwinSystem {
      inherit pkgs;
      specialArgs = {
        inherit inputs outputs hostname user;
      };
      modules = attrValues (import ../modules/darwin)
        ++ [
        ../hosts/${hostname}
        inputs.nur.nixosModules.nur
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            useGlobalPkgs = true;
            users.${user} = {
              imports = [ ../hosts/${hostname}/home-manager ]
                ++ attrValues (import ../modules/home-manager);
            };
            extraSpecialArgs = { inherit inputs outputs; };
            backupFileExtension = "backup";
          };
        }
      ];
    };

  # mkHomeManagerConfig =
  #   args@{ userHmConfig ? ./modules/home-manager/tiny.nix, ... }: {
  #     imports = [
  #       userHmConfig
  #       inputs.rokka-nvim.hmModule
  #       inputs.nix-doom-emacs.hmModule
  #     ];
  #     home = { stateVersion = "22.11"; };
  #   };

  # mkDarwinModules =
  #   args@{ user
  #   , hostname
  #   , userConfig ? ./modules/darwin/tiny.nix
  #   , userHomebrewConfig ? ./modules/homebrew/tiny.nix
  #   , nixpkgsConfig
  #   , ...
  #   }: [
  #     userConfig
  #     userHomebrewConfig
  #     home-manager.darwinModules.home-manager
  #     {
  #       nixpkgs = nixpkgsConfig;
  #       users.users.${user}.home = "/Users/${user}";
  #       home-manager = {
  #         useUserPackages = true;
  #         useGlobalPkgs = true;
  #         users.${user} = mkHomeManagerConfig args;
  #         # https://github.com/nix-community/home-manager/issues/1698
  #         extraSpecialArgs = args.specialArgs;
  #       };
  #     }
  #   ];

  mergeEnvs = { pkgs }:
    envs:
    pkgs.mkShell
      (
        builtins.foldl'
          (
            a:
            v:
            {
              buildInputs = a.buildInputs ++ v.buildInputs;
              nativeBuildInputs = a.nativeBuildInputs ++ v.nativeBuildInputs;
              propagatedBuildInputs = a.propagatedBuildInputs ++ v.propagatedBuildInputs;
              propagatedNativeBuildInputs = a.propagatedNativeBuildInputs ++ v.propagatedNativeBuildInputs;
              shellHook = a.shellHook + "\n" + v.shellHook;
            }
          )
          (pkgs.mkShell { })
          envs
      );

  # mkHome =
  #   { username
  #   , hostname ? null
  #   , pkgs ? outputs.nixosConfigurations.${hostname}.pkgs
  #   , persistence ? false
  #   , colorscheme ? null
  #   , wallpaper ? null
  #   , features ? [ ]
  #   }:
  #   homeManagerConfiguration {
  #     inherit pkgs;
  #     extraSpecialArgs = {
  #       inherit inputs outputs hostname username persistence
  #         colorscheme wallpaper features;
  #     };
  #     modules = attrValues (import ../modules/home-manager) ++ [ ../home/${username} ];
  #   };

  isDarwin = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];
  isLinux = system: builtins.elem system [ "x86_64-linux" ];
  /**
        * Check if `dir` contains a regular *file* of type `ext`
        * contains :: String -> Path -> Bool
        **/
  contains = ext: dir: (lists.length (regularOf ext dir)) > 0;

  stdenv.targetSystem = {
    isDarwinArm64 = stdenv.targetSystem.isDarwin && stdenv.targetSystem.darwinArch == "arm64";
  };
}
#https://github.com/archseer/snowflake/blob/master/lib/utils.nix can I move mergeEnvs here?
