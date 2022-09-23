{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs darwin;
  inherit (self) outputs;
  inherit (darwin.lib) darwinSystem;
  inherit (home-manager.lib) homeManagerConfiguration;

  inherit (builtins) elemAt match any mapAttrs attrValues attrNames listToAttrs;
  inherit (nixpkgs.lib) nixosSystem filterAttrs genAttrs mapAttrs' mapAttrsToList regularOf stdenv lists;
  inherit (lists) optional optionals;
in
rec {
  inherit optional optionals;
  # Applies a function to a attrset's names, while keeping the values
  mapAttrNames = f:
    mapAttrs' (name: value: {
      name = f name;
      inherit value;
    });

  has = element: any (x: x == element);

  toGuest = builtins.replaceStrings [ "darwin" ] [ "linux" ];
  mkVMNixOSSystem =
    { hostname
    , legacyPkgs
    , username ? "eyad"
    , guest-system
    , host-system
    }:
    nixosSystem {
      system = guest-system;
      pkgs = legacyPkgs.${guest-system};
      specialArgs = {
        inherit inputs outputs hostname username;
      };
      modules =
        attrValues (import ../modules/nixos)
        ++ [
          ../hosts/${hostname}
          # ../hosts/common/system/nixos
          # inputs.nur.nixosModules.nur
          { virtualisation.host.pkgs = legacyPkgs.${host-system}; }
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              users.${username} = {
                imports =
                  [
                    ../hosts/${hostname}/home-manager
                    # ../hosts/common/home-manager/nixos
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username; };
              backupFileExtension = "backup";
            };
          }
        ];
    };

  mkNixOSSystem =
    { hostname
    , legacyPkgs
    , username ? "eyad"
    , system
    , is-wsl ? false
    , colorscheme ? null
    , wallpaper ? null
    }:
    nixosSystem {
      inherit system;
      pkgs = legacyPkgs.${system};
      specialArgs = {
        inherit inputs outputs hostname username colorscheme wallpaper;
      };
      modules =
        attrValues (import ../modules/nixos)
        ++ (optional is-wsl inputs.nixos-wsl.nixosModules.wsl)
        ++ [
          ../hosts/${hostname}
          ../hosts/common/system/nixos
          inputs.nixpkgs.nixosModules.notDetected
          inputs.nur.nixosModules.nur

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              users.${username} = {
                imports =
                  [
                    ../hosts/${hostname}/home-manager
                    ../hosts/common/home-manager/nixos
                    # inputs.nix-doom-emacs.hmModule
                    inputs.nix-colors.homeManagerModule
                    inputs.spicetify-nix.homeManagerModule
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username colorscheme wallpaper; };
              backupFileExtension = "backup";
            };
          }
        ];
    };

  mkDarwinSystem =
    { hostname
    , legacyPkgs
    , username ? "eyad"
    , colorscheme ? null
    , system

    }:
    darwinSystem {
      pkgs = legacyPkgs.${system};
      inherit system;
      specialArgs = {
        inherit inputs outputs hostname username colorscheme;
      };
      modules =
        attrValues (import ../modules/darwin)
        ++ [
          ../hosts/${hostname}
          ../hosts/common/system/darwin
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              users.${username} = {
                imports =
                  [
                    ../hosts/common/home-manager/darwin

                    ../hosts/${hostname}/home-manager
                    inputs.nix-doom-emacs.hmModule
                    inputs.nix-colors.homeManagerModule
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username colorscheme; };
              backupFileExtension = "backup";
            };
          }
        ];
    };

  # mkHomeManagerConfig =
  #   args@{ userHmConfig ? ./modules/home-manager/tiny.nix, ... }: {
  #     imports = [
  #       userHmConfig
  #       inputs.rokka-nvim.hmModule
  #       inputs.nix-doom-emacs.hmModule
  #     ];
  #     home = { stateVersion = "22.11"; };
  #   };

  # mkDarwinModules =
  #   args@{ user
  #   , hostname
  #   , userConfig ? ./modules/darwin/tiny.nix
  #   , userHomebrewConfig ? ./modules/homebrew/tiny.nix
  #   , nixpkgsConfig
  #   , ...
  #   }: [
  #     userConfig
  #     userHomebrewConfig
  #     home-manager.darwinModules.home-manager
  #     {
  #       nixpkgs = nixpkgsConfig;
  #       users.users.${user}.home = "/Users/${user}";
  #       home-manager = {
  #         useUserPackages = true;
  #         useGlobalPkgs = true;
  #         users.${user} = mkHomeManagerConfig args;
  #         # https://github.com/nix-community/home-manager/issues/1698
  #         extraSpecialArgs = args.specialArgs;
  #       };
  #     }
  #   ];

  mergeEnvs = { pkgs }: envs:
    pkgs.mkShell
      (
        builtins.foldl'
          (
            a: v: {
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

  # mkHome =
  #   { username
  #   , hostname ? null
  #   , pkgs ? outputs.nixosConfigurations.${hostname}.pkgs
  #   , persistence ? false
  #   , colorscheme ? null
  #   , wallpaper ? null
  #   , features ? [ ]
  #   }:
  #   homeManagerConfiguration {
  #     inherit pkgs;
  #     extraSpecialArgs = {
  #       inherit inputs outputs hostname username persistence
  #         colorscheme wallpaper features;
  #     };
  #     modules = attrValues (import ../modules/home-manager) ++ [ ../home/${username} ];
  #   };

  isDarwin = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];
  isLinux = system: builtins.elem system [ "x86_64-linux" ];

  stdenv.targetSystem = {
    isDarwinArm64 = stdenv.targetSystem.isDarwin && stdenv.targetSystem.darwinArch == "arm64";
  };

  nixConfig = {
    # allowUnfree = true;
    permittedInsecurePackages = [ "electron-12.2.3" "electron-13.6.9" ];
    allowUnfreePredicate = pkg:
      builtins.elem (inputs.nixpkgs.lib.getName pkg)
        [
          "slack"
          "betterttv"
          "flagfox"
          "grammarly"
          "discord"
          "skypeforlinux"
          "zoom"
          "teams"
          "vk-messenger"
          "spotify"
          "spotify-unwrapped"
          "ngrok"
          "vscode"
          "corefonts"
          "teamviewer"
          "unrar"
          "obsidian"
          "yandex-disk"
          "notion-app-enhanced-v2.0.18"
          "dropbox"
          "mpv-convert-script"
          "video-cutter"
          "steamcmd"
          "steam-original"
          "steam-runtime"
          "broadcom-bt-firmware"
          "b43-firmware"
          "xow_dongle-firmware"
          "facetimehd-calibration"
          "facetimehd-firmware"
          "steam"
        ];
  };

  forAllSystems = genAttrs systems;
  systems = [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
