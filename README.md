# My Unified Nix Configurations (NixOS & macOS)

This repository contains my personal Nix configurations for both NixOS (Linux) and macOS (via nix-darwin), managed using a single Nix Flake.

## Structure

The configuration is organized into a feature-based modular structure:

*   **`flake.nix`**: The main entry point defining inputs (nixpkgs, home-manager, nix-darwin, etc.) and outputs (NixOS and Darwin configurations, formatters).
*   **`hosts/`**: Contains host-specific configurations.
    *   `hosts/workstation/`: Configuration for the NixOS machine.
        *   `default.nix`: Imports shared modules and sets NixOS-specific options.
        *   `hardware-configuration.nix`: Hardware profile for the NixOS machine.
    *   `hosts/macbook/`: Configuration for the macOS machine.
        *   `default.nix`: Imports shared and Darwin-specific modules, sets macOS-specific options.
*   **`modules/`**: Contains shared, reusable configuration modules organized by feature.
    *   `modules/nix/`: Core Nix settings (flakes, GC, unfree, etc.).
    *   `modules/shell/`: Shells (zsh, bash, nu), prompt (starship), CLI tools.
    *   `modules/dev/`: Development tools, editors (nixvim, helix, kakoune), languages, git config.
    *   `modules/apps/`: Common applications (managed via Home Manager where possible).
    *   `modules/ai/`: AI-related tools (lmstudio, ollama).
    *   `modules/services/`: System services (mostly Linux-specific: Tailscale, Pipewire, SSHd, etc.).
    *   `modules/security/`: Security settings (Firewall, Polkit - mostly Linux-specific).
    *   `modules/virtualization/`: Virtualization tools (Docker, Libvirt - Linux-specific).
    *   `modules/desktop/`: Linux Desktop Environments/Window Managers (with selection option).
    *   `modules/darwin/`: macOS-specific modules (Homebrew, system defaults, sketchybar, borders, etc.).
    *   `modules/host-users.nix`: Shared user and hostname configuration.
*   **`config/`**: Contains static configuration files linked by modules (e.g., sketchybar scripts).
*   **`Justfile`**: Provides convenient commands for managing the configurations (requires `just` to be installed).

## Usage

Ensure you have Nix with Flakes enabled installed on your target machine.

**Prerequisites:**

*   Install Nix: [https://nixos.org/download.html](https://nixos.org/download.html)
*   Enable Flakes: Add `experimental-features = nix-command flakes` to your Nix configuration (`/etc/nix/nix.conf` or `~/.config/nix/nix.conf`).
*   Install `just`: `nix-env -iA nixpkgs.just` (or add it via Home Manager).
*   (macOS only) Install Homebrew: [https://brew.sh/](https://brew.sh/) (if using the homebrew module).

**Applying the Configuration:**

1.  Clone this repository.
2.  Navigate into the repository directory.
3.  **(Optional)** Modify `flake.nix` or `hosts/<your-host>/default.nix` if your hostnames differ from "workstation" or "macbook". Update the `DARWIN_HOSTNAME` and `NIXOS_HOSTNAME` variables in the `Justfile`.
4.  **(Optional)** Adjust enabled features and options within the relevant host file (`hosts/workstation/default.nix` or `hosts/macbook/default.nix`).
5.  **(Optional but Recommended)** Copy your wallpaper for macOS Stylix to `config/darwin/wallpaper.png`.
6.  Run the appropriate `just` command:
    *   On NixOS: `just nixos` (or `just nixos-debug` for verbose output)
    *   On macOS: `just darwin` (or `just darwin-debug` for verbose output)

**Other Commands:**

*   `just update`: Update all flake inputs.
*   `just fmt`: Format all Nix code in the repository using Alejandra.
*   `just gc`: Run Nix garbage collection.
*   `just clean`: Remove build result symlinks.

## Customization

*   **Enable/Disable Features:** Modify the boolean options (e.g., `services.tailscale.enable = true;`, `dev.editors.helix.enable = false;`) within your host's `default.nix` file (`hosts/workstation/` or `hosts/macbook/`).
*   **Add New Shared Modules:** Create a new directory under `modules/`, add a `default.nix` defining options, add your configuration files (using `lib.mkIf` based on options), and import the new module in your host file(s).
*   **Add Darwin-Specific Config:** Add new `.nix` files under `modules/darwin/`, import them in `modules/darwin/default.nix`, and set options in `hosts/macbook/default.nix`.
*   **Add NixOS-Specific Config:** Add new `.nix` files under relevant feature directories (e.g., `modules/services/`), ensure they use `lib.mkIf pkgs.stdenv.isLinux`, import them in the feature's `default.nix`, and set options in `hosts/workstation/default.nix`.
