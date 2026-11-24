# Host to build: this machine's name unless given, e.g. `just build eyad-nixos`
host := `hostname -s`
# Omarchy on Arch: Home Manager only (homeConfigurations.<user>@<host>)
arch := path_exists("/etc/arch-release")
# `nh os` on NixOS, `nh darwin` on macOS, `nh home` on Arch
nh := if os() == "macos" { "nh darwin" } else if arch == "true" { "nh home" } else { "nh os" }
# nh names a NixOS/macOS host with -H, a Home Manager configuration with -c
target := if arch == "true" { "-c " + env("USER") + "@" } else { "-H " }

# List recipes, in this file's order: the two for every day first
default:
    @just --list --unsorted

# Make this machine match the repo: build, show the diff, activate (Arch: also installs what arch/<host>.packages has that's missing)
switch name=host:
    {{ if arch == "true" { "scripts/omarchy-links guard" } else { "true" } }}
    {{ if arch == "true" { "scripts/arch-system" } else { "true" } }}
    {{nh}} switch . {{target}}{{name}}{{ if arch == "true" { " -b hm-backup" } else { "" } }}
    {{ if arch == "true" { "scripts/arch-packages install " + name } else { "true" } }}

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

# Evaluate every configuration and the homelab test (evalTargets in flake.nix, the list CI uses) and check formatting, without building
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
    exit $failed

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

# Arch: show every file in ~ that `just switch` would replace or add, with diffs
[group('arch')]
arch-preview name=host:
    @scripts/arch-preview {{name}}

# Arch: the same, and archive the files it would touch to ~/hm-before-<date>.tar.gz
[group('arch')]
arch-backup name=host:
    @scripts/arch-preview {{name}} --backup

# Arch: install the root-owned files (nix.conf, the Spotify hook) that differ from arch/; `just switch` runs it, and `--check` only lists them
[group('arch')]
arch-system *args:
    @scripts/arch-system {{args}}

# Arch: rewrite arch/<host>.packages from what's installed, minus Omarchy's own lists (`just switch` does the reverse)
[group('arch')]
arch-save name=host:
    @scripts/arch-packages save {{name}}

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
