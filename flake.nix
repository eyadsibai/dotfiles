{
  description = "A very basic flake";

  inputs = {
    # nixpkgs.url = "nixpkgs/nixos-22.05";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    flake-utils.url = "github:numtide/flake-utils";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    fenix = {
      url = "github:nix-community/fenix"; # rust
      inputs.nixpkgs.follows = "nixpkgs";
    };

    base16.url = "github:SenchoPens/base16.nix";
    base16.inputs.nixpkgs.follows = "nixpkgs";

    base16-schemes = {
      url = "github:base16-project/base16-schemes";
      flake = false;
    };

    base16-zathura = {
      url = "github:haozeke/base16-zathura";
      flake = false;
    };

    base16-vim = {
      url = "github:base16-project/base16-vim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nur, home-manager, nix-colors
    , flake-utils, fenix, base16, base16-schemes, nix-doom-emacs, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-12.2.3" ];
        };

        overlays = [
          nur.overlay
          (import ./overlays/whatsapp.nix)
          inputs.neovim-nightly-overlay.overlay
        ];

      };

      lib = nixpkgs.lib;

    in {
      nixosConfigurations = {
        eyad-nixos = lib.nixosSystem {
          inherit system pkgs;

          modules = [
            # base16.nixosModule
            # { scheme = "${base16-schemes}/nord.yaml"; }
            nur.nixosModules.nur
            nixos-hardware.nixosModules.lenovo-thinkpad
            ./system/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.eyad = {
                imports = [
                  nix-doom-emacs.hmModule
                  ./home.nix
                  # ./theming.nix
                ];
              };
            }

          ];

          specialArgs = { inherit inputs; };
        };
      };
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fenixPkgs = fenix.packages.${system};
      in {
        devShells = {
          default = import ./shell.nix { inherit pkgs; };
          cc = import ./shells/cc.nix { inherit pkgs; };
          go = import ./shells/go.nix { inherit pkgs; };
          java = import ./shells/java.nix { inherit pkgs; };
          node = import ./shells/node.nix { inherit pkgs; };
          python = import ./shells/python.nix { inherit pkgs; };
          rust = import ./shells/rust.nix { inherit pkgs fenixPkgs; };
          ml = import ./shells/ml_no_cuda.nix { inherit pkgs; };
          sys-stats = import ./shells/sys-stats.nix { inherit pkgs; };
          db = import ./shells/db_dev.nix { inherit pkgs; };
          r = import ./shells/r.nix { inherit pkgs;};
          # android = import ./android.nix {inherit pkgs android-nixpkgs ; };
        };
      }));

}
