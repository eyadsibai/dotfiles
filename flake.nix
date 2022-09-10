{
  description = "My Ultimate Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    stable.url = "nixpkgs/nixos-22.05";

    hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:Mic92/nix-index-database";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    flake-utils.url = "github:numtide/flake-utils";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    mach-nix.url = "github:DavHau/mach-nix";
    firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    eww.url = "github:elkowar/eww";
    mpv-iptv = {
      url = "github:junners/mpv-iptv";
      flake = false;
    };

    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";
    base16 = {
      url = "github:SenchoPens/base16.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spacebar = {
      url = "github:cmacrae/spacebar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yabai-src = {
      url = "github:koekeishiya/yabai";
      flake = false;
    };
    spicetify-nix = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    polybar-themes = {
      url = "github:adi1090x/polybar-themes";
      flake = false;
    };
  };
  outputs = inputs:
    let
      lib = import ./lib { inherit inputs; };
      inherit (lib) forAllSystems mkNixOSSystem mkDarwinSystem;
    in
    rec {
      inherit lib;
      # Your custom packages and modifications
      overlays = {
        default = import ./overlay { inherit inputs lib; };
        nur = inputs.nur.overlay;
        neovim = inputs.neovim-nightly-overlay.overlay;
        poetry2nix = inputs.poetry2nix.overlay;
        spacebar = inputs.spacebar.overlay;
        nixpkgs-wayland = inputs.nixpkgs-wayland.overlay;
        nixgl = inputs.nixgl.overlay;
      };

      templates = import ./templates;

      legacyPackages =
        forAllSystems
          (
            system:
            import
              inputs.nixpkgs
              {
                hostPlatform = system;
                inherit system;
                overlays = builtins.attrValues overlays;
                config = lib.nixConfig;
              }
          );

      devShells =
        forAllSystems
          (
            system:
            let
              pkgs = legacyPackages.${system};
            in
            rec {
              default = pkgs.callPackage ./shell.nix { };
              cc = pkgs.callPackage ./shells/cc.nix { };
              go = pkgs.callPackage ./shells/go.nix { };
              java = import ./shells/java.nix { inherit pkgs; };
              # demonstrate two ways
              node = import ./shells/node.nix { inherit pkgs; };
              python = import ./shells/python.nix { inherit pkgs inputs; };
              rust = import ./shells/rust.nix { inherit pkgs; };
              ml_old = import ./shells/ml_no_cuda.nix { inherit pkgs; };
              sys-stats = import ./shells/sys-stats.nix { inherit pkgs; };
              db = import ./shells/db_dev.nix { inherit pkgs; };
              r = import ./shells/r.nix { inherit pkgs; };
              port-scanners = import ./shells/penetration/port-scanners.nix { inherit pkgs; };
              load-testing = import ./shells/penetration/load-testing.nix { inherit pkgs; };
              password = import ./shells/penetration/password.nix { inherit pkgs; };
              mysql = import ./shells/mysql.nix { inherit pkgs; };
              penetration-full = lib.mergeEnvs { inherit pkgs; } [ port-scanners load-testing password ];
              ml = import ./shells/ml { inherit pkgs; };
            }
          );

      nixosConfigurations."eyad-nixos" =
        mkNixOSSystem
          {
            hostname = "eyad-nixos";
            pkgs = legacyPackages.x86_64-linux;
            is-laptop = true;
            colorscheme = "tokyo-night-storm";
            wallpaper = "aurora-borealis-water-mountain";
          };

      nixosConfigurations."desktop-nixos-wsl" =
        mkNixOSSystem
          {
            hostname = "desktop-nixos-wsl";
            pkgs = legacyPackages.x86_64-linux;
            is-wsl = true;
          };

      nixosConfigurations."home-server" =
        mkNixOSSystem
          {
            hostname = "home-server";
            pkgs = legacyPackages.x86_64-linux;
          };

      darwinConfigurations."eyad-mac" =
        mkDarwinSystem
          {
            hostname = "eyad-mac";
            pkgs = legacyPackages.aarch64-darwin;
            colorscheme = "tokyo-night-storm";
          };
    };
}
