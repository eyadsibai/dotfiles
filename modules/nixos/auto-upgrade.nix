# Unattended upgrades for hosts nobody sits at (home-server). Two sources:
#   "github": the host evaluates and builds the repo's master itself (default)
#   "nixbot": the host takes what the self-hosted CI on the workstation last built
#             for it, from the workstation's binary cache. Parked along with the CI:
#             modules/nixos/ci/nixbot.nix adds it when imported.
#
# From GitHub, it upgrades only to a commit I signed (modules/common/signing-key.nix).
# Whoever got push access to the repo, or into my GitHub account, would otherwise run
# their code as root here by the next morning. A tip it won't take fails the upgrade,
# which says so on ntfy, and the host stays as it is.
#
# No host uses it: home-server is deployed by hand (`just deploy`). Master's commits
# aren't signed any more (1Password's signing kept failing), so turning it on means
# signing again, or a signed branch to follow (69657cf had a `just promote` for that).
{
  config,
  options,
  lib,
  pkgs,
  useremail,
  ...
}:
let
  cfg = config.my.autoUpgrade;
  host = config.networking.hostName;
  checkout = "/var/lib/nixos-upgrade/dotfiles";
  allowedSigners = pkgs.writeText "allowed-signers" ''
    ${useremail} namespaces="git" ${import ../common/signing-key.nix}
  '';
in
{
  options.my.autoUpgrade = {
    enable = lib.mkEnableOption "upgrading this host on a timer from the repo";
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
    allowReboot = lib.mkEnableOption ''
      rebooting after an upgrade that changed the kernel, initrd or kernel modules,
      between 04:00 and 06:00 (from GitHub only)
    '';
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.from == "github" || options.my ? ci;
            message = "my.autoUpgrade.from = \"nixbot\" needs the CI module, which is parked (docs/ci.md).";
          }
        ];
      }
      (lib.mkIf (cfg.from == "github") {
        system.autoUpgrade = {
          enable = true;
          # The checkout below, once its tip has passed the signature check
          flake = "git+file://${checkout}?ref=master#${host}";
          inherit (cfg) dates;
          randomizedDelaySec = "30min";
          operation = "switch";
          # Only when the kernel, initrd or modules changed (nixpkgs compares them)
          inherit (cfg) allowReboot;
          rebootWindow = {
            lower = "04:00";
            upper = "06:00";
          };
        };

        systemd.services.nixos-upgrade.preStart = ''
          git() { ${lib.getExe pkgs.git} -C ${checkout} "$@"; }
          if [[ ! -d ${checkout}/.git ]]; then
            mkdir -p ${checkout}
            git init --quiet --initial-branch=master
            git remote add origin https://github.com/eyadsibai/dotfiles.git
          fi
          git fetch --quiet origin master
          if ! git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile=${allowedSigners} \
              verify-commit FETCH_HEAD; then
            echo "master's tip, $(git rev-parse --short FETCH_HEAD), is not signed by my key: not upgrading" >&2
            exit 1
          fi
          # Every old commit is signed too, so a branch forced back to one would
          # pass the check and undo fixes since. Only move forward.
          if git rev-parse --verify --quiet master > /dev/null &&
            ! git merge-base --is-ancestor master FETCH_HEAD; then
            echo "master on GitHub, $(git rev-parse --short FETCH_HEAD), doesn't follow from the last upgrade, $(git rev-parse --short master): not upgrading" >&2
            exit 1
          fi
          git checkout --quiet -B master FETCH_HEAD
        '';
      })
    ]
  );
}
