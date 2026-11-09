# Self-hosted CI, kept ready but off: nixbot (github.com/Mic92/nixbot) on the workstation
# builds every host, home and package in this repo (`ciJobs`, see nixbot.toml) whenever
# master moves, and Harmonia serves the results as a binary cache on the tailnet.
# GitHub Actions stays the CI of record; this is for when it isn't enough (it can't build
# CUDA or the Macs' Linux VMs in reasonable time) or for hosts upgrading from CI builds
# (my.autoUpgrade.from = "nixbot").
#
# Pull-based: it polls GitHub, so no GitHub App, webhook or open port is needed. Builds
# only run for commits signed with my 1Password key (verify-commit-signature below).
#
# To turn it on (docs/ci.md has the details):
#   1. nix key generate-secret --key-name workstation-1 > key; nix key convert-secret-to-public < key
#   2. just secret nixbot   # cache-signing-key: |  (the secret key)
#   3. my.ci.nixbot.enable = true on the workstation; my.ci.cachePublicKey everywhere
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.ci;

  # The commit-signing key (modules/home/onepassword.nix)
  allowedSigners = pkgs.writeText "ci-allowed-signers" ''
    * namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpovYakzNvqZRJKiE7H43QJ1Y1zJt3ixf+tvzDBNXJe
  '';
in
{
  imports = [ inputs.nixbot.nixosModules.nixbot ];

  options.my.ci = {
    nixbot.enable = lib.mkEnableOption "the nixbot CI service and its binary cache on this host";
    useCache = lib.mkEnableOption "the CI's binary cache on the workstation as a substituter";
    cachePublicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "workstation-1:AbC...=";
      description = "The cache's public signing key (nix key convert-secret-to-public).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.nixbot.enable {
      services.nixbot = {
        enable = true;
        # Reached over Tailscale as http://workstation
        domain = config.networking.hostName;
        buildSystems = [
          "x86_64-linux"
          "aarch64-linux" # the Mac VMs, through QEMU (below)
        ];
        evalWorkerCount = 4;
        evalMaxMemorySize = 8192;
        buildConcurrency = 8;
        pullBased.repositories."eyadsibai/dotfiles" = {
          url = "https://github.com/eyadsibai/dotfiles.git";
          defaultBranch = "master";
          pollInterval = 300;
        };
        postBuildSteps = [
          {
            name = "verify-commit-signature";
            warnOnly = false;
            command = [
              "${pkgs.git}/bin/git"
              "-c"
              "gpg.format=ssh"
              "-c"
              "gpg.ssh.program=${pkgs.openssh}/bin/ssh-keygen"
              "-c"
              "gpg.ssh.allowedSignersFile=${allowedSigners}"
              "verify-commit"
              "--"
              (inputs.nixbot.lib.interpolate "%(prop:revision)s")
            ];
          }
        ];
        # Only the tailnet can reach it (firewall below), and being on it is trust enough
        allowUnauthenticatedControl = true;
      };

      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      sops.secrets.cache-signing-key = {
        sopsFile = ../../../secrets/nixbot.yaml;
        key = "cache-signing-key";
      };
      services.harmonia = {
        enable = true;
        signKeyPaths = [ config.sops.secrets.cache-signing-key.path ];
        settings.bind = "[::]:5000";
      };

      # The web UI (nginx, port 80) and the cache, on Tailscale only
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        80
        5000
      ];
    })

    (lib.mkIf cfg.useCache {
      assertions = [
        {
          assertion = cfg.cachePublicKey != null;
          message = "my.ci.useCache needs my.ci.cachePublicKey, the CI cache's public key.";
        }
      ];
      nix.settings = {
        extra-substituters = [ "http://workstation:5000" ];
        extra-trusted-public-keys = lib.optional (cfg.cachePublicKey != null) cfg.cachePublicKey;
      };
    })
  ];
}
