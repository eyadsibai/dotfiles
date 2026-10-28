host := "workstation"

# List recipes
default:
    @just --list

# Build, show the package diff, then activate
switch:
    nh os switch . -H {{host}}

# Build and show the diff without activating
build:
    nh os build . -H {{host}}

# Activate on next boot only
boot:
    nh os boot . -H {{host}}

# Update all flake inputs (or one: just update nixpkgs)
update *inputs:
    nix flake update {{inputs}}

# Evaluate the configuration and run flake checks
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

# List system generations
generations:
    nixos-rebuild list-generations
