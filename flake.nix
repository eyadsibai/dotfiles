{
  description = "My Ultimate Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    stable.url = "nixpkgs/nixos-22.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:Mic92/nix-index-database";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    mach-nix.url = "github:DavHau/mach-nix";
    firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";

    mpv-iptv =
      {
        url = "github:junners/mpv-iptv";
        flake = false;
      };

    nixgl = {
      #OpenGL
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    poetry2nix.url = "github:nix-community/poetry2nix";

    spacebar.url = "github:cmacrae/spacebar/master";
    nixpkgs-wayland = { url = "github:nix-community/nixpkgs-wayland"; };
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    # nixpkgs-wayland.inputs.master.follows = "master";

  };
  outputs =
    inputs:
    let
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
      systems = [
        # "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      lib = import ./lib { inherit inputs; };
      nixConfig = {
        allowUnfree = true;
        permittedInsecurePackages = [ "electron-12.2.3" "electron-13.6.9" ];
        allowUnfreePredicate = [ "slack" ];
      };
    in
    rec {
      # inherit lib;
      # Your custom packages and modifications
      common-overlays = {
        default = import ./overlay/common { inherit inputs lib nixConfig; };
        nur = inputs.nur.overlay;
        neovim = inputs.neovim-nightly-overlay.overlay;
        poetry2nix = inputs.poetry2nix.overlay;
      };

      nixos-overlays = {
        # nixgl = inputs.nixgl.overlay.nixgl;
        nixpkgs-wayland = inputs.nixpkgs-wayland.overlay;
      };

      darwin-overlays = {
        default = import ./overlay/darwin { inherit inputs lib nixConfig; };
        firefox-darwin = inputs.firefox-darwin.overlay;
        spacebar = inputs.spacebar.overlay;
      };

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      darwinModules = import ./modules/darwin;

      templates = import ./templates;

      isDarwin = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];
      isLinux = system: builtins.elem system [ "x86_64-linux" ];

      # Reexport nixpkgs with our overlays applied
      # Acessible on our configurations, and through nix build, shell, run, etc.
      legacyPackages =
        forAllSystems
          (
            system:
            import
              inputs.nixpkgs
              {
                inherit system;
                overlays = builtins.attrValues common-overlays
                  ++ (
                  inputs.nixpkgs.lib.lists.optionals
                    (isDarwin system)
                    (builtins.attrValues
                      darwin-overlays)
                )
                  ++ (
                  inputs.nixpkgs.lib.lists.optionals
                    (isLinux system)
                    (builtins.attrValues
                      nixos-overlays)
                );

                config = nixConfig;
              }

          );
      # Devshell for bootstrapping
      # Acessible through 'nix develop'
      devShells =
        forAllSystems
          (
            system:
            let
              pkgs = legacyPackages.${ system };
              mergeEnvs =
                envs:
                pkgs.mkShell
                  (
                    builtins.foldl'
                      (
                        a:
                        v:
                        {
                          buildInputs = a.buildInputs ++ v.buildInputs;
                          nativeBuildInputs = a.nativeBuildInputs ++ v.nativeBuildInputs;
                          propagatedBuildInputs = a.propagatedBuildInputs ++ v.propagatedBuildInputs;
                          propagatedNativeBuildInputs = a.propagatedNativeBuildInputs ++ v.propagatedNativeBuildInputs;
                          shellHook = a.shellHook + "\n" + v.shellHook;
                        }
                      )
                      (pkgs.mkShell { })
                      envs
                  );
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
              ml = import ./shells/ml_no_cuda.nix { inherit pkgs; };
              sys-stats = import ./shells/sys-stats.nix { inherit pkgs; };
              db = import ./shells/db_dev.nix { inherit pkgs; };
              r = import ./shells/r.nix { inherit pkgs; };
              port-scanners = import ./shells/penetration/port-scanners.nix { inherit pkgs; };
              load-testing = import ./shells/penetration/load-testing.nix { inherit pkgs; };
              password = import ./shells/penetration/password.nix { inherit pkgs; };
              mysql = import ./shells/mysql.nix { inherit pkgs; };
              penetration-full = mergeEnvs [ port-scanners load-testing password ];
            }
          );
      nixosConfigurations."eyad-nixos" =
        inputs.nixpkgs.lib.nixosSystem
          {
            system = "x86_64-linux";
            pkgs = legacyPackages.x86_64-linux;
            modules =
              [
                ./hosts/eyad-nixos/nixos/configuration.nix
                inputs.nixos-hardware.nixosModules.lenovo-thinkpad
                inputs.nixpkgs.nixosModules.notDetected
                inputs.nur.nixosModules.nur
                # inputs.stylix.nixosModules.stylix (stylix.image must be set)
                inputs.base16.nixosModule
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.backupFileExtension = "backup";
                  home-manager.extraSpecialArgs = { inherit inputs; };
                  home-manager.users.eyad = {
                    imports =
                      [
                        ./hosts/eyad-nixos/home-manager/home.nix


                        # Import our reusable home-manager modules;
                      ]
                      ++ (builtins.attrValues homeManagerModules);
                  };
                }
                # Import our reusable nixos modules;
              ]
              ++ (builtins.attrValues nixosModules);
            specialArgs = { inherit inputs; };
          };
      darwinConfigurations."eyad-mac" =
        inputs.darwin.lib.darwinSystem
          {
            system = "aarch64-darwin";
            pkgs = legacyPackages.aarch64-darwin;
            modules = [
              # https://gitlab.com/azazel/ender-config/-/blob/master/flake.nix#L50
              ./hosts/eyad-mac/darwin/configuration.nix

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.users.eyad = {
                  imports =
                    [
                      ./hosts/eyad-mac/home-manager/home.nix

                      # Import our reusable home-manager modules;

                    ] ++ (builtins.attrValues homeManagerModules);
                };
              }

            ]
            ++ (builtins.attrValues darwinModules);

            specialArgs = { inherit inputs; };

          };
    };
}
