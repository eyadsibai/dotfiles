{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs darwin;
  inherit (self) outputs;
  inherit (darwin.lib) darwinSystem;
  inherit (home-manager.lib) homeManagerConfiguration;

  inherit (builtins) elemAt match any mapAttrs attrValues attrNames listToAttrs;
  inherit (nixpkgs.lib) nixosSystem filterAttrs genAttrs mapAttrs' mapAttrsToList lists regularOf stdenv;
in
rec {
  # Applies a function to a attrset's names, while keeping the values
  mapAttrNames = f: mapAttrs' (name: value: { name = f name; inherit value; });

  has = element: any (x: x == element);

  mkNixOsSystem =
    { hostname
    , pkgs
    , default-user
    }:
    nixosSystem {
      inherit pkgs;
      specialArgs = {
        inherit inputs outputs hostname;
      };
      modules = attrValues (import ../modules/nixos) ++ [ ../hosts/${hostname} ];
    };

  mkHomeManagerConfig =
    args@{ userHmConfig ? ./modules/home-manager/tiny.nix, ... }: {
      imports = [
        userHmConfig
        inputs.rokka-nvim.hmModule
        inputs.nix-doom-emacs.hmModule
      ];
      home = { stateVersion = "22.11"; };
    };

  mkDarwinModules =
    args@{ user
    , hostname
    , userConfig ? ./modules/darwin/tiny.nix
    , userHomebrewConfig ? ./modules/homebrew/tiny.nix
    , nixpkgsConfig
    , ...
    }: [
      userConfig
      userHomebrewConfig
      home-manager.darwinModules.home-manager
      {
        nixpkgs = nixpkgsConfig;
        users.users.${user}.home = "/Users/${user}";
        home-manager = {
          useUserPackages = true;
          useGlobalPkgs = true;
          users.${user} = mkHomeManagerConfig args;
          # https://github.com/nix-community/home-manager/issues/1698
          extraSpecialArgs = args.specialArgs;
        };
      }
    ];
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
