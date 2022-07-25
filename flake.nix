{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    flake-utils.url = "github:numtide/flake-utils";
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, nixos-hardware, nur, home-manager, nix-colors
    , flake-utils, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-12.2.3" ];
        };

        overlays = [ nur.overlay (import ./overlays/whatsapp.nix) ];

      };

      lib = nixpkgs.lib;

    in {
      nixosConfigurations = {
        eyad-nixos = lib.nixosSystem {
          inherit system pkgs;

          modules = [
            nur.nixosModules.nur
            nixos-hardware.nixosModules.lenovo-thinkpad
            ./system/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              # home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.eyad = { imports = [ ./home.nix ]; };
            }
          ];
        };
      };
    } // (flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells = {
          default = import ./shells/shell.nix { inherit pkgs; };
          cc = import ./shells/cc.nix { inherit pkgs; };
          go = import ./shells/go.nix { inherit pkgs; };
          java = import ./shells/java.nix { inherit pkgs; };
          node = import ./shells/node.nix { inherit pkgs; };
          python = import ./shells/python.nix { inherit pkgs; };
          rust = import ./shells/rust.nix { inherit pkgs; };
          ml = import ./shells/ml_no_cuda.nix { inherit pkgs; };
          # android = import ./android.nix {inherit pkgs android-nixpkgs ; };
        };
      }));

}
