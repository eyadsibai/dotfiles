{
  description = "My Ultimate Flake";
  inputs = {
    unstable.url = "nixpkgs/nixos-unstable";
    stable.url = "nixpkgs/nixos-22.05";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:Mic92/nix-index-database";

    home-manager = {
      # url = "github:nix-community/home-manager/release-22.11";
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
    devshell.url = "github:numtide/devshell";
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

    # nixpkgs-wayland = {
    #   url = "github:nix-community/nixpkgs-wayland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # hyprland = {
    #   url = "github:hyprwm/hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hyprwm-contrib = {
    #   url = "github:hyprwm/contrib";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    spicetify-nix = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    polybar-themes = {
      url = "github:adi1090x/polybar-themes";
      flake = false;
    };

    flake-utils-plus = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
    };
    macos-builder.url = "github:Gabriella439/macos-builder";

  };
  outputs = inputs:
    let
      lib = import ./lib { inherit inputs; };
      inherit (lib) forAllSystems mkNixOSSystem mkVMNixOSSystem mkDarwinSystem mergeEnvs nixConfig toGuest;

      overlays = {
        default = import ./overlay { inherit inputs lib; };
        nur = inputs.nur.overlay;
        neovim = inputs.neovim-nightly-overlay.overlay;
        poetry2nix = inputs.poetry2nix.overlay;
        # nixpkgs-wayland = inputs.nixpkgs-wayland.overlay;
        nixgl = inputs.nixgl.overlay;
        devshell = inputs.devshell.overlay;
        # comma = (inputs.flake-utils-plus.lib.genPkgOverlay inputs.comma "comma");
        # comma = inputs.comma.overlays.default;
      };

      legacyPackages = forAllSystems (system:
        import
          inputs.nixpkgs
          {
            inherit system;
            overlays = builtins.attrValues overlays;
            config = nixConfig;
          }
      );
    in
    rec {
      inherit lib;
      inherit overlays;
      inherit legacyPackages;

      # packages = forAllSystems (system:
      #   let pkgs = legacyPackages.${system};
      #   in import ./pkgs { inherit inputs pkgs; }
      # );


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
          mkNixOSSystem {
            hostname = "eyad-nixos";
            system = "x86_64-linux";
            inherit legacyPackages;
            #        is-laptop = true;
            colorscheme = "tokyo-night-storm";
            wallpaper = "aurora-borealis-water-mountain";
          };

        "vm-linux-aarch64-darwin" = mkVMNixOSSystem {
          hostname = "vm-linux-aarch64-darwin";
          guest-system = "aarch64-linux";
          host-system = "aarch64-darwin";
          inherit legacyPackages;
        };
      };
    };
}
