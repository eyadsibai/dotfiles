# Unattended upgrades for hosts nobody sits at (home-server). Two sources:
#   "github": the host evaluates and builds github:eyadsibai/dotfiles itself (default)
#   "nixbot": the host takes what the self-hosted CI on the workstation last built
#             for it, from the workstation's binary cache (modules/nixos/ci/nixbot.nix)
{ config, lib, ... }:
let
  cfg = config.my.autoUpgrade;
  host = config.networking.hostName;
in
{
  imports = [ ./nixbot-auto-upgrade.nix ];

  options.my.autoUpgrade = {
    enable = lib.mkEnableOption "upgrading this host on a timer from the repo's master branch";
    from = lib.mkOption {
      type = lib.types.enum [
        "github"
        "nixbot"
      ];
      default = "github";
      description = "Build the upgrade here from GitHub, or take the CI's build of it.";
    };
    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:00";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.from == "github") {
        system.autoUpgrade = {
          enable = true;
          flake = "github:eyadsibai/dotfiles#${host}";
          inherit (cfg) dates;
          randomizedDelaySec = "30min";
          # Reboots only for a new kernel or initrd would need allowReboot; a server
          # picks those up at its next reboot instead
          operation = "switch";
        };
      })
      (lib.mkIf (cfg.from == "nixbot") {
        system.nixbotAutoUpgrade = {
          enable = true;
          inherit (cfg) dates;
          instance = "http://workstation";
          project = "pull_based/eyadsibai/dotfiles";
          branch = "master";
          source = "git+https://github.com/eyadsibai/dotfiles?ref=master";
          job = "ciJobs.hosts.${host}";
        };
        my.ci.useCache = true;
      })
    ]
  );
}
