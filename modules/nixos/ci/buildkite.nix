# Buildkite agents for integration tests.
#
# Not imported yet. To enable:
#   1. just secret buildkite      # add `agent-token:` and `ssh-key: |` (deploy key for private repos)
#   2. import this file from hosts/workstation/default.nix
#
# Jobs run as dedicated system users (buildkite-agent-<name>) with Docker access,
# which is root-equivalent: only connect pipelines for your own, trusted code,
# never ones that build pull requests from forks.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  agents = [
    "it-1"
    "it-2"
  ];
  secretsGroup = "buildkite-secrets";
  secret = key: {
    sopsFile = ../../../secrets/buildkite.yaml;
    inherit key;
    group = secretsGroup;
    mode = "0440";
  };
in
{
  users.groups.${secretsGroup} = { };
  sops.secrets.buildkite-agent-token = secret "agent-token";
  sops.secrets.buildkite-ssh-key = secret "ssh-key";

  services.buildkite-agents = lib.genAttrs agents (_: {
    tokenPath = config.sops.secrets.buildkite-agent-token.path;
    privateSshKeyPath = config.sops.secrets.buildkite-ssh-key.path;
    extraGroups = [
      "docker"
      secretsGroup
    ];
    tags = {
      queue = "integration";
      os = "nixos";
      gpu = "rtx4090";
    };
    # Pipelines can run `nix develop -c <test command>` to use each project's flake toolchain
    runtimePackages = with pkgs; [
      bash
      coreutils
      gnutar
      gzip
      git
      nix
      docker-client
    ];
  });

  # Keep the desktop usable while tests run: lower CPU priority, cap memory per agent
  systemd.services = lib.genAttrs (map (a: "buildkite-agent-${a}") agents) (_: {
    serviceConfig = {
      CPUWeight = 50;
      MemoryHigh = "40G";
      MemoryMax = "48G";
    };
  });
}
