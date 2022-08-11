{
  description = "My Ultimate Flake";

  inputs = {
    # nixpkgs.url = "nixpkgs/nixos-22.05";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:Mic92/nix-index-database";
    sops-nix =
      {
        url = github:Mic92/sops-nix;
        inputs.nixpkgs.follows = "nixpkgs";
      };
    home-manager = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager-darwin = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    flake-utils.url = "github:numtide/flake-utils";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    mach-nix.url = "github:DavHau/mach-nix";
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";

    # THEMING

    nix-colors.url = "github:misterio77/nix-colors";
    base16 = {
      url = "github:SenchoPens/base16.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    stylix.url = "github:danth/stylix";
  };

  outputs = inputs:
    let
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
      systems = [
        # "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      lib = import ./lib { inherit inputs; };

    in
    rec {
      # inherit lib;

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;


      # Your custom packages and modifications
      overlays = {
        default = import ./overlay {
          inherit inputs lib;
        };
        nur = inputs.nur.overlay;
        neovim = inputs.neovim-nightly-overlay.overlay;
      };

      # Reexport nixpkgs with our overlays applied
      # Acessible on our configurations, and through nix build, shell, run, etc.
      legacyPackages =
        forAllSystems
          (
            system:
            import inputs.nixpkgs {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = [ "electron-12.2.3" "electron-13.6.9" ];
              };
            }
          );
      # Devshell for bootstrapping
      # Acessible through 'nix develop'
      devShells =
        forAllSystems
          (system:
            let
              pkgs = legacyPackages.${system};
              mergeEnvs = envs:
                pkgs.mkShell (builtins.foldl'
                  (a: v: {
                    buildInputs = a.buildInputs ++ v.buildInputs;
                    nativeBuildInputs = a.nativeBuildInputs ++ v.nativeBuildInputs;
                    propagatedBuildInputs = a.propagatedBuildInputs ++ v.propagatedBuildInputs;
                    propagatedNativeBuildInputs = a.propagatedNativeBuildInputs ++ v.propagatedNativeBuildInputs;
                    shellHook = a.shellHook + "\n" + v.shellHook;
                  })
                  (pkgs.mkShell { })
                  envs);
            in
            rec {
              default = pkgs.callPackage ./shell.nix { };
              cc = pkgs.callPackage ./shells/cc.nix { };
              go = pkgs.callPackage ./shells/go.nix { };
              java = import ./shells/java.nix { inherit pkgs; }; # demonstrate two ways
              node = import ./shells/node.nix { inherit pkgs; };
              python = import ./shells/python.nix { inherit pkgs inputs; };
              rust = import ./shells/rust.nix { inherit pkgs; };
              ml = import ./shells/ml_no_cuda.nix { inherit pkgs; };
              sys-stats = import ./shells/sys-stats.nix { inherit pkgs; };
              db = import ./shells/db_dev.nix { inherit pkgs; };
              r = import ./shells/r.nix { inherit pkgs; };
              port-scanners = import ./shells/penetration/port-scanners.nix { inherit pkgs; };
              load-testing = import ./shells/penetration/load-testing.nix { inherit pkgs; };
              password = import ./shells/penetration/password.nix { inherit pkgs; };
              penetration-full = mergeEnvs [ port-scanners load-testing password ];
            });

      nixosConfigurations."eyad-nixos" = inputs.nixpkgs.lib.nixosSystem {
        pkgs = legacyPackages.x86_64-linux;

        modules =
          [
            ./hosts/linux/eyad-nixos/nixos/configuration.nix
            inputs.sops-nix.nixosModules.sops
            inputs.nixos-hardware.nixosModules.lenovo-thinkpad
            inputs.nixpkgs.nixosModules.notDetected
            inputs.nur.nixosModules.nur
            # inputs.base16.nixosModules
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.eyad = {
                imports =
                  [
                    ./hosts/linux/eyad-nixos/home-manager
                    inputs.nix-doom-emacs.hmModule
                    # Import our reusable home-manager modules;
                  ]
                  ++ (builtins.attrValues homeManagerModules);
              };
            }
            # Import our reusable nixos modules;
          ]
          ++ (builtins.attrValues nixosModules);

        specialArgs = {
          inherit inputs;
        };
      };

      darwinConfiguration."eyad-mac" = inputs.darwin.lib.darwinSystem {
        pkgs = legacyPackages.aarch64-darwin;

        modules = [
          ./hosts/mac/darwin/nixos/configuration.nix
          { pkgs.overlays = [ inputs.firefox-darwin.overlay ]; }
          inputs.home-manager.darwinModule.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
