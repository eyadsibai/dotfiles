# Unattended upgrades for hosts nobody sits at (home-server). Two sources:
#   "github": the host evaluates and builds a branch of the repo itself (default)
#   "nixbot": the host takes what the self-hosted CI on the workstation last built
#             for it, from the workstation's binary cache. Parked along with the CI:
#             modules/nixos/ci/nixbot.nix adds it when imported.
#
# From GitHub, it upgrades only to a commit I signed (modules/common/signing-key.nix).
# Whoever got push access to the repo, or into my GitHub account, would otherwise run
# their code as root here by the next morning. A tip it won't take fails the upgrade,
# which says so on ntfy, and the host stays as it is.
#
# home-server follows the `server` branch rather than master, so a flake.lock update
# reaches it only after the desktops have run it. Commits on master aren't signed
# (1Password's signing kept failing); `just promote` adds one signed commit to
# `server` with master's files, so only that one signature is needed.
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
  inherit (cfg) branch;
  host = config.networking.hostName;
  checkout = "/var/lib/nixos-upgrade/dotfiles";
  allowedSigners = pkgs.writeText "allowed-signers" ''
    ${useremail} namespaces="git" ${import ../common/signing-key.nix}
  '';
in
{
  options.my.autoUpgrade = {
    enable = lib.mkEnableOption "upgrading this host on a timer from the repo";
    branch = lib.mkOption {
      type = lib.types.str;
      default = "master";
      example = "server";
      description = "The branch it upgrades to (from GitHub).";
    };
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
          flake = "git+file://${checkout}?ref=${branch}#${host}";
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
            git init --quiet --initial-branch=${branch}
            git remote add origin https://github.com/eyadsibai/dotfiles.git
          fi
          git fetch --quiet origin ${branch}
          if ! git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile=${allowedSigners} \
              verify-commit FETCH_HEAD; then
            echo "${branch}'s tip, $(git rev-parse --short FETCH_HEAD), is not signed by my key: not upgrading" >&2
            exit 1
          fi
          # Every old commit is signed too, so a branch forced back to one would
          # pass the check and undo fixes since. Only move forward.
          if git rev-parse --verify --quiet ${branch} > /dev/null &&
            ! git merge-base --is-ancestor ${branch} FETCH_HEAD; then
            echo "${branch} on GitHub, $(git rev-parse --short FETCH_HEAD), doesn't follow from the last upgrade, $(git rev-parse --short ${branch}): not upgrading" >&2
            exit 1
          fi
          git checkout --quiet -B ${branch} FETCH_HEAD
        '';
      })
    ]
  );
}
