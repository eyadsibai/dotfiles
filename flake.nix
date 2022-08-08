{
  description = "My Ultimate Flake";

  inputs = {
    # nixpkgs.url = "nixpkgs/nixos-22.05";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin-nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-20.09-darwin";

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "darwin-nixpkgs";
    };




    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    flake-utils.url = "github:numtide/flake-utils";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    mach-nix.url = "github:DavHau/mach-nix";
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

  outputs =
    { self
    , nixpkgs
    , nixos-hardware
    , nur
    , home-manager
    , nix-colors
    , flake-utils
    , fenix
    , base16
    , base16-schemes
    , nix-doom-emacs
    , mach-nix
    , darwin
    , ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-12.2.3" "electron-13.6.9" ];
        };

        overlays = [
          nur.overlay
          (import ./overlays/whatsapp.nix)
          inputs.neovim-nightly-overlay.overlay
        ];

      };

      lib = nixpkgs.lib;

      mergeEnvs = envs: pkgs.mkShell (builtins.foldl'
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
    {
      nixosConfigurations = {
        eyad-nixos = lib.nixosSystem {
          inherit system pkgs;

          modules = [
            # base16.nixosModule
            # { scheme = "${base16-schemes}/nord.yaml"; }
            nur.nixosModules.nur
            nixos-hardware.nixosModules.lenovo-thinkpad
            ./hosts/linux/eyad-nixos/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.eyad = {
                imports = [
                  nix-doom-emacs.hmModule
                  ./hosts/linux/eyad-nixos/home.nix
                  # ./theming.nix
                ];
              };
            }

          ];

          specialArgs = { inherit inputs; };
        };
      };

      darwinConfiguration."" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [ ];
        inputs = { inherit darwin; };
      };
    } // (flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      fenixPkgs = fenix.packages.${system};

    in
    {
      devShells = rec {
        default = import ./shell.nix { inherit pkgs; };
        cc = import ./shells/cc.nix { inherit pkgs; };
        go = import ./shells/go.nix { inherit pkgs; };
        java = import ./shells/java.nix { inherit pkgs; };
        node = import ./shells/node.nix { inherit pkgs; };
        python = import ./shells/python.nix { inherit pkgs mach-nix nixpkgs; };
        rust = import ./shells/rust.nix { inherit pkgs; };
        ml = import ./shells/ml_no_cuda.nix { inherit pkgs; };
        sys-stats = import ./shells/sys-stats.nix { inherit pkgs; };
        db = import ./shells/db_dev.nix { inherit pkgs; };
        r = import ./shells/r.nix { inherit pkgs; };
        port-scanners = import ./shells/penetration/port-scanners.nix { inherit pkgs; };
        load-testing = import ./shells/penetration/load-testing.nix { inherit pkgs; };
        password = import ./shells/penetration/password.nix { inherit pkgs; };
        penetration-full = mergeEnvs [ port-scanners load-testing password ];
        # android = import ./android.nix {inherit pkgs android-nixpkgs ; };
      };
    }));

}
