{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs darwin;
  inherit (self) outputs;
  inherit (darwin.lib) darwinSystem;
  inherit (home-manager.lib) homeManagerConfiguration;
  inherit (nixpkgs.lib) mkOption types count nixosSystem filterAttrs genAttrs mapAttrs' mapAttrsToList regularOf stdenv lists makeExtensible foldr;


  # Import necessary builtins
  inherit (builtins) elemAt match any mapAttrs attrValues attrNames listToAttrs elem;
  inherit (lists) optional optionals;

  # Custom helper to convert an attrset to a list of { name = ..., value = ... } pairs.
  # Similar to lib.mapAttrsToList but with a specific output structure.
  attrsToList = attrs:
    mapAttrsToList (name: value: { inherit name value; }) attrs;

in
rec
{
  # --- Attribute Set Manipulation Helpers ---

  # Filters and maps an attribute set simultaneously.
  # Applies predicate `pred` and mapping function `f`.
  # mapFilterAttrs :: (name -> value -> bool) -> (name -> value -> { name = any; value = any; }) -> attrs -> attrs
  mapFilterAttrs = pred: f: attrs: filterAttrs pred (mapAttrs' f attrs);

  # Generates an attribute set by applying function `f` to each value in the input `values` list.
  # genAttrs' :: [a] -> (a -> { name = string; value = any; }) -> attrs
  genAttrs' = values: f: listToAttrs (map f values);

  # Checks if any attribute in `attrs` satisfies the predicate `pred`.
  # anyAttrs :: (name -> value -> bool) -> attrs -> bool
  anyAttrs = pred: attrs:
    any (attr: pred attr.name attr.value) (attrsToList attrs);

  # Counts how many attributes in `attrs` satisfy the predicate `pred`.
  # countAttrs :: (name -> value -> bool) -> attrs -> int
  countAttrs = pred: attrs:
    count (attr: pred attr.name attr.value) (attrsToList attrs);

  # Applies a function `f` to the names of attributes in `attrs`, keeping the values.
  # mapAttrNames :: (string -> string) -> attrs -> attrs
  mapAttrNames = f:
    mapAttrs' (name: value: {
      name = f name;
      inherit value;
    });


  # --- NixOS Module Option Helpers ---

  # Shortcut for creating a NixOS option with type and default.
  mkOpt = type: default:
    mkOption { inherit type default; };

  mkOpt' = type: default: description:
    mkOption { inherit type default description; };

  mkBoolOpt = default: mkOption {
    inherit default;
    type = types.bool;
    example = true;
  };


  # --- System Configuration Builders ---

  # Builds a NixOS configuration for a Virtual Machine.
  mkVMNixOSSystem =
    { hostname
    , legacyPackages
    , username ? "eyad"
    , guest-system
    , host-system
    }:
    nixosSystem {
      system = guest-system;
      pkgs = legacyPackages.${guest-system};
      specialArgs = {
        inherit inputs outputs hostname username;
      };
      modules =
        # attrValues (import ../modules/nixos)
        # ++
        [

          ../hosts/${hostname}
          # ../hosts/common/system/nixos
          inputs.nur.modules.nixos.default

          { virtualisation.host.pkgs = legacyPackages.${host-system}; }
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              users.${username} = {
                imports =
                  [
                    ../hosts/${hostname}/home-manager
                    # ../hosts/common/home-manager/nixos
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username; };
              backupFileExtension = "backup";
            };
          }
        ];
    };

  # Builds a standard NixOS configuration.
  mkNixOSSystem =
    { hostname
    , legacyPackages
    , username ? "eyad"
    , system
    , is-wsl ? false
    , colorscheme ? null
    , wallpaper ? null
    }:
    nixosSystem {
      inherit system;
      pkgs = legacyPackages.${system};
      specialArgs = {
        inherit inputs outputs hostname username colorscheme wallpaper;
      };
      modules =
        attrValues (import ../modules/nixos)
        ++ (optional is-wsl inputs.nixos-wsl.nixosModules.wsl)
        ++ [
          ../hosts/${hostname}
          ../hosts/common/system/nixos
          inputs.nixpkgs.nixosModules.notDetected
          inputs.nur.modules.nixos.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.nix-index

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              backupFileExtension = "backup";

              users.${username} = {
                imports =
                  [

                    # ../hosts/${hostname}/home-manager
                    ../hosts/common/home-manager/nixos

                    # inputs.nix-doom-emacs.hmModule
                    # inputs.spicetify-nix.homeManagerModule
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username colorscheme wallpaper; };

            };
          }
        ];
    };

  # Builds a nix-darwin (macOS) configuration.
  mkDarwinSystem =
    { hostname
    , legacyPackages
    , username ? "eyad"
    , colorscheme ? null
    , system

    }:
    darwinSystem {
      pkgs = legacyPackages.${system};
      inherit system;
      specialArgs = {
        inherit inputs outputs hostname username colorscheme;
      };
      modules =
        attrValues (import ../modules/darwin)
        ++ [
          ../hosts/${hostname}
          ../hosts/common/system/darwin
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              users.${username} = {
                imports =
                  [
                    ../hosts/common/home-manager/darwin

                    # ../hosts/${hostname}/home-manager
                    inputs.nix-doom-emacs.hmModule
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username colorscheme; };
              backupFileExtension = "backup";
            };
          }
        ];
    };


  # --- System Type Checks ---

  # Checks if the system is a Darwin (macOS) system.
  isDarwin = system: elem system [ "aarch64-darwin" "x86_64-darwin" ];
  # Checks if the system is a Linux system (more comprehensive).
  isLinux = system: elem system [ "x86_64-linux" "aarch64-linux" "i686-linux" ];


  # --- Stdenv Extensions ---

  # Extend stdenv.targetSystem with a specific check for ARM64 Darwin.
  stdenv.targetSystem = {
    isDarwinArm64 = stdenv.targetSystem.isDarwin && stdenv.targetSystem.darwinArch == "arm64";
  };


  # --- Global Nix Configuration Settings ---

  # Common Nix settings applied via legacyPackages.
  nixConfig = {
    permittedInsecurePackages = [
      "electron-12.2.3"
      # "electron-13.6.9" # Example commented out insecure package
      # "electron-14.2.9"
      "electron-21.4.0"
      "electron-19.1.9"
    ];
    # Allow installation of unfree packages system-wide.
    allowUnfree = true;
  };


  # --- Flake Output Helpers ---

  # List of systems to generate outputs for.
  forAllSystems = genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "i686-linux" # 32-bit Linux
  ];

  # Helper to potentially map host system types to guest types (e.g., for VMs).
  toGuest = builtins.replaceStrings [ "darwin" ] [ "linux" ];

  # Merges multiple dev shell environments (mkShell arguments) into one.
  # Combines inputs, hooks, etc.
  mergeEnvs = { pkgs }: envs:
    pkgs.mkShell (
        builtins.foldl'
          (
            a: v: {
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


}
