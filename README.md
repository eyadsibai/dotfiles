# My NixOS & macOS Dotfiles

This repository contains my personal configuration files managed using Nix Flakes. It sets up environments for NixOS, macOS (via nix-darwin), and WSL, along with various development tools and custom packages.

## Features

- **Cross-Platform:** Manages configurations for NixOS, macOS, and WSL.
- **Nix Flakes:** Uses the modern Nix Flakes feature for reproducibility and dependency management.
- **Home Manager:** Manages user-specific configurations and packages.
- **Custom Packages:** Includes custom Nix packages in the `pkgs/` directory.
- **Development Shells:** Provides pre-configured development environments via `devshell`.
- **Modular Design:** Configurations are broken down into reusable modules.

## Structure

- **`flake.nix`**: The main entry point defining inputs and outputs.
- **`hosts/`**: Contains system-specific configurations (NixOS, macOS, WSL).
  - **`common/`**: Shared configuration modules across different hosts.
- **`modules/`**: Reusable configuration modules categorized by system type (nixos, darwin, home-manager).
- **`pkgs/`**: Custom Nix packages built for this configuration.
- **`overlay/`**: Nixpkgs overlays to modify or add packages.
- **`lib/`**: Helper functions used throughout the configuration.
- **`dev-shells/`**: Definitions for development environments using `devshell`.
- **`templates/`**: Project templates usable with `nix flake new`.
- **`scripts/`**: Utility scripts categorized by function (wm, media, plot, utils, system, to_be_fixed).
- **`misc/`**: Miscellaneous configuration files and data.
  - **`data/`**: Non-script data files previously in `misc/bin`.
- **`secrets/`**: Placeholder for secrets management (implementation details may vary).
- **`justfile`**: Task runner definitions using `just`.

## Usage

This repository uses `just` as a task runner for common operations.

- **List available tasks:**
  ```bash
  just
  ```
- **Update flake inputs:**
  ```bash
  just update
  ```
- **Update flake inputs and commit `flake.lock`:**
  ```bash
  just update_commit # or just uc
  ```
- **Apply NixOS configuration:** (Run on the target NixOS machine)
  ```bash
  sudo nixos-rebuild switch --flake .#<hostname>
  # Example: sudo nixos-rebuild switch --flake .#eyad-nixos
  # Using just: sudo just build_switch # or sudo just bs
  ```
- **Apply Home Manager configuration:** (Run on the target machine)
  ```bash
  home-manager switch --flake .#<username>@<hostname>
  # Example: home-manager switch --flake .#eyad@eyad-nixos
  # Using just: just home_switch # or just hs
  ```
- **Apply macOS configuration:** (Run on the target macOS machine)
  ```bash
  darwin-rebuild switch --flake .#<hostname>
  # Example: darwin-rebuild switch --flake .#eyad-mac
  ```
- **Check flake:**
  ```bash
  nix flake check
  # Using just: just check
  ```

## Setup on a New System

*(Instructions to be added - depends on specific system setup process)*

## Inspirations

*(Existing inspirations can be kept or updated)*
-

## TODO

- Review and potentially further organize scripts in `scripts/`.
- Add detailed setup instructions for new systems.
- Add a LICENSE file.
- Consider adding a CONTRIBUTING.md.
