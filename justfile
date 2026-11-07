# Host to build: this machine's name unless given, e.g. `just build eyad-nixos`
host := `hostname -s`
# Omarchy on Arch: Home Manager only (homeConfigurations.<user>@<host>)
arch := path_exists("/etc/arch-release")
# `nh os` on NixOS, `nh darwin` on macOS, `nh home` on Arch
nh := if os() == "macos" { "nh darwin" } else if arch == "true" { "nh home" } else { "nh os" }
# nh names a NixOS/macOS host with -H, a Home Manager configuration with -c
target := if arch == "true" { "-c " + env("USER") + "@" } else { "-H " }

# List recipes
default:
    @just --list

# Build, show the package diff, then activate
switch name=host:
    {{ if arch == "true" { "scripts/omarchy-links guard" } else { "true" } }}
    {{nh}} switch . {{target}}{{name}}{{ if arch == "true" { " -b hm-backup" } else { "" } }}

# Build and show the diff without activating
build name=host:
    {{nh}} build . {{target}}{{name}}

# Activate on next boot only (NixOS)
boot name=host:
    nh os boot . -H {{name}}

# Boot a NixOS host in a throwaway VM (no NVIDIA) to try desktop changes
vm name=host:
    nix run .#nixosConfigurations.{{name}}.config.system.build.vm

# Update all flake inputs, nixarchy included (or only some: just update nixpkgs home-manager)
update *inputs:
    nix flake update {{inputs}}

# Evaluate every host and run flake checks
check:
    nix flake check

# Format all Nix files
fmt:
    nix fmt

# Delete old generations and garbage-collect the store
clean:
    nh clean all --keep-since 7d --keep 10

# Edit (or create) an encrypted secrets file: secrets/<name>.yaml
secret name:
    sops secrets/{{name}}.yaml

# List system generations (NixOS)
generations:
    nixos-rebuild list-generations

# Arch: show every file in ~ that `just switch` would replace or add, with diffs
[group('arch')]
arch-preview name=host:
    @scripts/arch-preview {{name}}

# Arch: the same, and archive the files it would touch to ~/hm-before-<date>.tar.gz
[group('arch')]
arch-backup name=host:
    @scripts/arch-preview {{name}} --backup

# Arch: install what arch/<host>.packages lists and is missing (never removes)
[group('arch')]
arch-sync name=host:
    #!/usr/bin/env bash
    set -uo pipefail
    mapfile -t wanted < <(grep -Ev '^(#|$)' arch/{{name}}.packages)
    # pacman -T counts what an installed package provides; yay --needed goes by name,
    # so it would offer power-profiles-daemon over omarchy-power-profiles-daemon.
    mapfile -t missing < <(pacman -T "${wanted[@]}")
    if ((${#missing[@]} == 0)); then
      echo "Everything in arch/{{name}}.packages is installed."
      exit 0
    fi
    yay -S --needed "${missing[@]}"

# Arch: rewrite arch/<host>.packages from what's installed, minus Omarchy's own lists
[group('arch')]
arch-save name=host:
    #!/usr/bin/env bash
    set -euo pipefail
    omarchy=$(cat "${OMARCHY_PATH:-/usr/share/omarchy}"/install/*.packages | sed 's/#.*//' | tr -s ' \t' '\n' | sort -u)
    { echo "# Installed on {{name}} beyond Omarchy's own lists; \`just arch-save\` rewrites this"
      comm -23 <(pacman -Qqe | sort -u) <(echo "$omarchy"); } > arch/{{name}}.packages
    git diff --stat arch/{{name}}.packages

# Update Omarchy, then walk through links, defaults, diff, switch, commit and reboot, asking at each step
[group('omarchy')]
omarchy-upgrade:
    @scripts/omarchy-upgrade

# Show which files in files/ override an Omarchy default that changed upstream
[group('omarchy')]
omarchy-check:
    @scripts/omarchy-defaults check

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

# Bring upstream changes to those defaults into your versions (3-way merge, git diff to review)
[group('omarchy')]
omarchy-merge:
    @scripts/omarchy-defaults merge
