{ lib, config, pkgs, ... }:

let
  cfg = config.nix;
  stdenv = pkgs.stdenv;
in
{
  options.nix = {
    # Common Settings
    allowUnfree = lib.mkEnableOption "Allow unfree packages from nixpkgs";
    enableFlakes = lib.mkEnableOption "Enable Nix Flakes support";
    gc = {
      deleteOlderThan = lib.mkOption {
        type = lib.types.str;
        default = "7d";
        description = "How long to keep garbage collection generations.";
      };
    };


    # Linux Specific Settings
    linux = {
      sandbox = lib.mkEnableOption "Enable sandboxing (Linux)";
      cudaSupport = lib.mkEnableOption "Enable CUDA support in nixpkgs (Linux)";
      keepOutputs = lib.mkEnableOption "Keep build outputs (Linux)";
      keepDerivations = lib.mkEnableOption "Keep derivations (Linux)";
      maxJobs = lib.mkOption {
        type = lib.types.int;
        default = 32;
        description = "Max parallel build jobs (Linux)";
      };
      cores = lib.mkOption {
        type = lib.types.int;
        default = 0; # 0 means use all available
        description = "Number of cores to use for builds (Linux)";
      };
      substituters = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ "https://cache.nixos.org/" ];
        description = "List of Nix binary cache substituters (Linux)";
      };
      trustedPublicKeys = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
        description = "List of trusted public keys for substituters (Linux)";
      };
    };

    # Darwin Specific Settings
    darwin = {
      hostPlatform = lib.mkOption {
        type = lib.types.str;
        default = "aarch64-darwin"; # Or "x86_64-darwin"
        description = "Host platform for nixpkgs on Darwin";
      };
      nixbldGID = lib.mkOption {
        type = lib.types.int;
        default = 30000;
        description = "Group ID for nixbld users (Darwin)";
      };
      enableLinuxBuilder = lib.mkEnableOption "Enable Linux builder VM on Darwin";
    };
  };

  config = {
    # Apply Common Settings
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    # nix.settings.experimental-features = lib.mkIf cfg.enableFlakes [ "nix-command" "flakes" ]; # Merged below
    nix.gc = {
      options = "--delete-older-than ${cfg.gc.deleteOlderThan}";
    };
    # Only set optimise.automatic on Linux, Darwin has its own implementation

    # nix.optimise.automatic = lib.mkIf stdenv.isLinux cfg.optimize.automatic;

    # Apply Linux Specific Settings
    nix.settings = lib.mkMerge [
      (lib.mkIf cfg.enableFlakes { experimental-features = [ "nix-command" "flakes" ]; })
      (lib.mkIf stdenv.isLinux {
        sandbox = cfg.linux.sandbox;
        keep-outputs = cfg.linux.keepOutputs;
        keep-derivations = cfg.linux.keepDerivations;
        max-jobs = cfg.linux.maxJobs;
        cores = cfg.linux.cores;
        substituters = cfg.linux.substituters;
        trusted-public-keys = cfg.linux.trustedPublicKeys;
        auto-optimise-store = lib.mkIf (cfg.optimise ? automatic) cfg.optimise.automatic; # NixOS puts this here
      })
      # Add Darwin specific nix.settings here if needed, e.g.
      # (lib.mkIf stdenv.isDarwin { /* ... */ })
    ];
    nixpkgs.config.cudaSupport = lib.mkIf (stdenv.isLinux && cfg.linux.cudaSupport) true;

    # Apply Darwin Specific Settings
    # max-jobs = cfg.linux.maxJobs; # Removed duplicate
    nixpkgs.hostPlatform = lib.mkIf stdenv.isDarwin cfg.darwin.hostPlatform;
    ids.gids.nixbld = lib.mkIf stdenv.isDarwin cfg.darwin.nixbldGID;
    nix.package = lib.mkIf stdenv.isDarwin pkgs.nix; # Darwin core specified this
    nix.linux-builder.enable = lib.mkIf (stdenv.isDarwin && cfg.darwin.enableLinuxBuilder) true;

    # Darwin doesn't use nix.settings for auto-optimise-store? Check nix-darwin docs if needed.
    # nix.settings = lib.mkIf stdenv.isDarwin { }; # Keep empty settings block from Darwin core?
  };
}
