{
  description = "My Ultimate Flake";
  inputs = {
    unstable.url = "nixpkgs/nixos-unstable";
    # stable.url = "nixpkgs/nixos-23.11";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";


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

    stylix.url = "github:danth/stylix";


    # nixpkgs-wayland = {
    #   url = "github:nix-community/nixpkgs-wayland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:A1ca7raz/spicetify-nix";
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
        nur = inputs.nur.overlay;
        neovim = inputs.neovim-nightly-overlay.overlays.default;
        # poetry2nix = inputs.poetry2nix.overlay;
        # nixpkgs-wayland = inputs.nixpkgs-wayland.overlay;
        nixgl = inputs.nixgl.overlay;
        devshell = inputs.devshell.overlays.default;
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
      # nixosModules = mapModulesRec ./modules/nixos import;
      darwinModules = import ./modules/darwin;
      homeManagerModules = import ./modules/home-manager;
      # gamingModules = import ./modules/gaming;

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
          mkSingleUserNixOSSystem {
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
