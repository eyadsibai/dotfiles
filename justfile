# Host to build: this machine's name unless given, e.g. `just build eyad-nixos`
host := `hostname -s`
# Omarchy on Arch, which has steps of its own: Omarchy's links, pacman's packages
arch := path_exists("/etc/arch-release")
# Home Manager only (homeConfigurations.<user>@<host>): a Linux that isn't NixOS, so the Arch machines and spark
home := if os() == "macos" { "false" } else if path_exists("/etc/NIXOS") == "true" { "false" } else { "true" }
# Ubuntu (spark), where Nix installs my programs and apt only what's in apt/<host>.packages
apt := path_exists("/usr/bin/apt-get")
# `nh os` on NixOS, `nh darwin` on macOS, `nh home` where Home Manager is on its own
nh := if os() == "macos" { "nh darwin" } else if home == "true" { "nh home" } else { "nh os" }
# nh names a NixOS/macOS host with -H, a Home Manager configuration with -c
target := if home == "true" { "-c " + env("USER") + "@" } else { "-H " }

# List recipes, in this file's order: the two for every day first
default:
    @just --list --unsorted

# Make this machine match the repo: build, show the diff, activate (Arch/spark: also syncs listed packages, asking about removed, replaced, and unlisted ones)
switch name=host:
    {{ if arch == "true" { "scripts/omarchy-links guard" } else { "true" } }}
    {{ if home == "true" { "scripts/host-system" } else { "true" } }}
    {{nh}} switch . {{target}}{{name}}{{ if home == "true" { " -b hm-backup" } else { "" } }}
    {{ if arch == "true" { "scripts/arch-packages install " + name } else if apt == "true" { "scripts/apt-packages install " + name } else { "true" } }}

# Pull, get the newest of everything, then switch; the same on every machine, asking at each step (Arch: `omarchy update` too)
upgrade:
    @scripts/upgrade

# Build and show the diff without activating
build name=host:
    {{nh}} build . {{target}}{{name}}

# Activate on next boot only (NixOS)
boot name=host:
    nh os boot . -H {{name}}

# Boot a NixOS host in a throwaway VM (no NVIDIA) to try desktop changes
vm name=host:
    nix run .#nixosConfigurations.{{name}}.config.system.build.vm

# Only move flake.lock, without switching: every input, or the ones named (just update nixpkgs home-manager)
update *inputs:
    nix flake update {{inputs}}

# Evaluate every configuration and the homelab test (evalTargets in flake.nix, the list CI uses), check formatting, and run repo-wide linters, without building
check:
    #!/usr/bin/env bash
    set -uo pipefail
    targets=$(nix eval --raw .#evalTargets --apply 'builtins.concatStringsSep "\n"') || exit 1
    failed=0
    while IFS= read -r target; do
      echo "eval $target"
      nix eval --raw ".#$target.drvPath" >/dev/null || { echo "FAILED: $target"; failed=1; }
    done <<<"$targets"
    nix fmt -- --ci || failed=1
    scripts/lint || failed=1
    exit $failed

# Run repo-wide Nix, shell, and Python linters (statix, deadnix, shellcheck, ruff)
lint:
    @scripts/lint

# Format all Nix files
fmt:
    nix fmt

# Build a NixOS host here and switch it over SSH (addr defaults to its Tailscale name).
# A new kernel, initrd or kernel modules (the NVIDIA driver among them) only take
# effect after a reboot, so it says when one is due.
deploy name addr=name:
    NIX_SSHOPTS="-A" nix run --inputs-from . nixpkgs#nixos-rebuild-ng -- switch --flake .#{{name}} --target-host {{addr}} --sudo --ask-sudo-password
    @ssh {{addr}} 'for f in kernel initrd kernel-modules; do [ "$(readlink /run/booted-system/$f)" = "$(readlink /run/current-system/$f)" ] || { echo "Reboot {{name}} to finish: its $f changed (ssh {{addr}} sudo reboot)"; break; }; done'

# Delete old generations and garbage-collect the store
clean:
    nh clean all --keep-since 7d --keep 10

# Edit (or create) an encrypted secrets file: secrets/<name>.yaml
secret name:
    sops secrets/{{name}}.yaml

# List system generations (NixOS)
generations:
    nixos-rebuild list-generations

# First, in the VM: `sudo passwd root`; then here: `ssh-copy-id root@<ip>`. Wipes its disk.
# Mac: install vm-fusion or vm-utm on a new VM booted from the aarch64 NixOS ISO
[group('vm')]
vm-install name addr:
    nix run --inputs-from . nixpkgs#nixos-anywhere -- --flake .#{{name}} --target-host root@{{addr}}

# The new Mac needs Nix installed and `trusted-users = eyad` in its nix.conf.
# Mac: build a Mac's system here and copy it to a new Mac, so its first switch builds nothing
[group('mac')]
mac-copy name addr:
    nix build .#darwinConfigurations.{{name}}.system
    nix copy -s --to "ssh-ng://{{addr}}?remote-program=/nix/var/nix/profiles/default/bin/nix-daemon" ./result

# Arch and spark: show every file in ~ that `just switch` would replace or add, with diffs
[group('home')]
home-preview name=host:
    @scripts/home-preview {{name}}

# Arch and spark: the same, and archive the files it would touch to ~/hm-before-<date>.tar.gz
[group('home')]
home-backup name=host:
    @scripts/home-preview {{name}} --backup

# Arch and spark: install the root-owned files (nix.conf, on Arch the Spotify hook) that differ from arch/ and add the firewall rules arch/<host>.ufw lists that are missing; `just switch` runs it, and `--check` only lists them
[group('home')]
host-system *args:
    @scripts/host-system {{args}}

# Arch: rewrite arch/<host>.packages from what's installed, minus Omarchy's own lists and arch/common.packages (`just switch` does the reverse)
[group('arch')]
arch-save name=host:
    @scripts/arch-packages save {{name}}

# Arch: go through every difference between installed packages and arch/common.packages + arch/<host>.packages (uninstalled, replaced, and unlisted), one at a time (`just switch` asks too)
[group('arch')]
arch-review name=host:
    @scripts/arch-packages review {{name}}

# spark: rewrite apt/<host>.packages from what I've installed with apt on top of the image (`just switch` does the reverse)
[group('apt')]
apt-save name=host:
    @scripts/apt-packages save {{name}}

# spark: go through apt package differences (uninstalled, unlisted, or duplicated by Nix), one at a time (`just switch` asks too)
[group('apt')]
apt-review name=host:
    @scripts/apt-packages review {{name}}

# List every Omarchy default that changed since I last went through them, overridden here or not (--diff shows the diffs)
[group('omarchy')]
omarchy-check *args:
    @scripts/omarchy-defaults check {{args}}

# Diff my setup against stock Omarchy, every template (--stat for the summary, or name paths: hypr kitty)
[group('omarchy')]
omarchy-diff *args:
    @scripts/omarchy-diff {{args}}

# Show linked files an Omarchy update detached, and migrations that touched linked files
[group('omarchy')]
omarchy-links:
    @scripts/omarchy-links check

# Copy detached files into the repo, relink them, and mark migrations reviewed
[group('omarchy')]
omarchy-adopt:
    @scripts/omarchy-links adopt

# Go through those changes one at a time: Omarchy's diff, then merge it into mine (3-way), keep mine, or decide later
[group('omarchy')]
omarchy-review:
    @scripts/omarchy-defaults review
