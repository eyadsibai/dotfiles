{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs darwin;
  inherit (self) outputs; # Assuming outputs might be needed, adjust if not
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
  # Adapted from dotfiles repo, simplified to match current repo structure

  # Builds a standard NixOS configuration.
  mkNixOSSystem =
    { hostname
    , system
    , specialArgs ? {} # Allow passing extra args
    , modules ? [] # Allow passing extra modules
    }:
    nixosSystem {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
      specialArgs = { inherit inputs outputs hostname; } // specialArgs; # Merge base args with provided ones
      modules = [ ../hosts/${hostname} ] ++ modules; # Include host-specific path + extra modules
    };

  # Builds a nix-darwin (macOS) configuration.
  mkDarwinSystem =
    { hostname
    , system
    , specialArgs ? {} # Allow passing extra args
    , modules ? [] # Allow passing extra modules
    }:
    darwinSystem {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
      specialArgs = { inherit inputs outputs hostname; } // specialArgs; # Merge base args with provided ones
      modules = [ ../hosts/${hostname} ] ++ modules; # Include host-specific path + extra modules
    };


  # --- System Type Checks ---

  # Checks if the system is a Darwin (macOS) system.
  isDarwin = system: elem system [ "aarch64-darwin" "x86_64-darwin" ];
  # Checks if the system is a Linux system (more comprehensive).
  isLinux = system: elem system [ "x86_64-linux" "aarch64-linux" "i686-linux" ];


  # --- Stdenv Extensions ---

  # Extend stdenv.targetSystem with a specific check for ARM64 Darwin.
  # Note: This might not be strictly necessary depending on usage, but included for completeness
  stdenv = nixpkgs.legacyPackages.x86_64-linux.stdenv; # Use a default stdenv for this check
  stdenv.targetSystem = {
    isDarwinArm64 = stdenv.targetSystem.isDarwin && stdenv.targetSystem.darwinArch == "arm64";
  };


  # --- Global Nix Configuration Settings ---
  # Example from dotfiles, adjust as needed for this repo's context
  nixConfig = {
    permittedInsecurePackages = [
      # Add any insecure packages used in this repo if necessary
      # "electron-12.2.3"
    ];
    # Allow installation of unfree packages system-wide.
    allowUnfree = true; # Assuming this is desired, matches current repo's host configs
  };


  # --- Flake Output Helpers ---

  # List of systems to generate outputs for.
  # Use the systems defined in the main flake.nix
  # forAllSystems = genAttrs [
  #   "aarch64-linux"
  #   "x86_64-linux"
  #   "aarch64-darwin"
  #   "x86_64-darwin"
  # ];

  # Helper to potentially map host system types to guest types (e.g., for VMs).
  toGuest = builtins.replaceStrings [ "darwin" ] [ "linux" ];

  # Merges multiple dev shell environments (mkShell arguments) into one.
  # Keep this if dev shells are defined using mkShell directly
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
