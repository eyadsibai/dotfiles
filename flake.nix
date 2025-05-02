{
  description = "My Ultimate Flake";
  inputs = {
    # Main Nixpkgs input, tracking nixos-unstable.
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # Hardware-specific configurations.
    hardware.url = "github:NixOS/nixos-hardware";
    # Nix User Repository for community packages/modules.
    nur.url = "github:nix-community/NUR";
    # Database for nix-index tool.
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager for user-level configuration.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix support for macOS.
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NixOS on Windows Subsystem for Linux.
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    # Utilities for flakes (though custom lib.forAllSystems is used here).
    flake-utils.url = "github:numtide/flake-utils";
    # Doom Emacs configuration flake.
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    # Overlay for nightly Neovim builds.
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    # Firefox builds specifically for Darwin.
    firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    # ElKowar's Wacky Widgets.
    eww.url = "github:elkowar/eww";
    # Development shell environment tooling.
    devshell.url = "github:numtide/devshell";

    # MPV script for IPTV (non-flake input).
    mpv-iptv = {
      url = "github:junners/mpv-iptv";
      flake = false;
    };

    # Wrapper for running GUI apps with proprietary NVIDIA drivers.
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System-wide theming and colorscheme management.
    stylix.url = "github:danth/stylix";

    # Hyprland Wayland compositor.
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plugins for Hyprland.
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Contrib scripts and tools for Hyprland.
    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };


  };
  outputs = inputs:
    let
      lib = import ./lib { inherit inputs; };
      inherit (lib) forAllSystems mkNixOSSystem mkVMNixOSSystem
        mkDarwinSystem mergeEnvs nixConfig toGuest mkSingleUserNixOSSystem
        ;

      overlays = {
        default = import ./overlay { inherit inputs lib; };
        nur = inputs.nur.overlays.default;
        neovim = inputs.neovim-nightly-overlay.overlays.default;
        nixgl = inputs.nixgl.overlay;
        devshell = inputs.devshell.overlays.default;
      };

      legacyPackages = forAllSystems (system:
        import
          inputs.nixpkgs
          {
            inherit system;
            # Apply all defined overlays.
            # builtins.attrValues converts the attribute set 'overlays' into a list of overlay functions.
            overlays = builtins.attrValues overlays;
            config = nixConfig;
          }
      );
    in
    rec {
      inherit lib;
      inherit overlays;
      inherit legacyPackages;


      templates = import ./templates;

      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      homeManagerModules = import ./modules/home-manager;

      devShells = forAllSystems (system:
        let
          pkgs = legacyPackages.${system};
        in
        import ./dev-shells { inherit pkgs lib; }
      );

      formatter = forAllSystems (pkgs: pkgs.alejandra);


      darwinConfigurations = {
        "eyad-mac" =
          mkDarwinSystem {
            hostname = "eyad-mac";
            system = "aarch64-darwin";
            inherit legacyPackages;
            colorscheme = "tokyo-night-storm";
          };
      };

      nixosConfigurations = {
        "home-server" =
          mkNixOSSystem {
            hostname = "home-server";
            system = "x86_64-linux";
            inherit legacyPackages;
          };
        "desktop-nixos-wsl" =
          mkNixOSSystem {
            hostname = "desktop-nixos-wsl";
            system = "x86_64-linux";
            inherit legacyPackages;
            is-wsl = true;
          };

        "eyad-nixos" =
          # Using the consolidated mkNixOSSystem function
          mkNixOSSystem {
            hostname = "eyad-nixos";
            system = "x86_64-linux";
            inherit legacyPackages;
            #        is-laptop = true;
            colorscheme = "tokyo-night-storm";
            wallpaper = "aurora-borealis-water-mountain";
          };


      };
    };
}
