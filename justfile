# Host to build: this machine's name unless given, e.g. `just build eyad-nixos`
host := `hostname -s`
# `nh os` on NixOS, `nh darwin` on macOS
nh := if os() == "macos" { "nh darwin" } else { "nh os" }

# List recipes
default:
    @just --list

# Build, show the package diff, then activate
switch name=host:
    {{nh}} switch . -H {{name}}

# Build and show the diff without activating
build name=host:
    {{nh}} build . -H {{name}}

# Activate on next boot only (NixOS)
boot name=host:
    nh os boot . -H {{name}}

# Boot a NixOS host in a throwaway VM (no NVIDIA) to try desktop changes
vm name=host:
    nix run .#nixosConfigurations.{{name}}.config.system.build.vm

# Update all flake inputs (or one: just update nixpkgs)
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
