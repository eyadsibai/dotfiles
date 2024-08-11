{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs darwin;
  inherit (self) outputs;
  inherit (darwin.lib) darwinSystem;
  inherit (home-manager.lib) homeManagerConfiguration;
  inherit (nixpkgs.lib) mkOption types count nixosSystem filterAttrs genAttrs mapAttrs' mapAttrsToList regularOf stdenv lists makeExtensible foldr;



  inherit (builtins) elemAt match any mapAttrs attrValues attrNames listToAttrs;
  inherit (lists) optional optionals;
  # attrsToList
  attrsToList = attrs:
    mapAttrsToList (name: value: { inherit name value; }) attrs;

in
rec
{

  # mapFilterAttrs ::
  #   (name -> value -> bool)
  #   (name -> value -> { name = any; value = any; })
  #   attrs
  mapFilterAttrs = pred: f: attrs: filterAttrs pred (mapAttrs' f attrs);

  # Generate an attribute set by mapping a function over a list of values.
  genAttrs' = values: f: listToAttrs (map f values);

  # anyAttrs :: (name -> value -> bool) attrs
  anyAttrs = pred: attrs:
    any (attr: pred attr.name attr.value) (attrsToList attrs);

  # countAttrs :: (name -> value -> bool) attrs
  countAttrs = pred: attrs:
    count (attr: pred attr.name attr.value) (attrsToList attrs);

  mkOpt = type: default:
    mkOption { inherit type default; };

  mkOpt' = type: default: description:
    mkOption { inherit type default description; };

  mkBoolOpt = default: mkOption {
    inherit default;
    type = types.bool;
    example = true;
  };

  # Applies a function to a attrset's names, while keeping the values
  mapAttrNames = f:
    mapAttrs' (name: value: {
      name = f name;
      inherit value;
    });

  mkVMNixOSSystem =
    { hostname
    , legacyPackages
    , username ? "eyad"
    , guest-system
    , host-system
    }:
    nixosSystem {
      system = guest-system;
      pkgs = legacyPackages.${guest-system};
      specialArgs = {
        inherit inputs outputs hostname username;
      };
      modules =
        # attrValues (import ../modules/nixos)
        # ++
        [

          ../hosts/${hostname}
          # ../hosts/common/system/nixos
          inputs.nur.nixosModules.nur
          { virtualisation.host.pkgs = legacyPackages.${host-system}; }
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
    , legacyPackages
    , username ? "eyad"
    , system
    , is-wsl ? false
    , colorscheme ? null
    , wallpaper ? null
    }:
    nixosSystem {
      inherit system;
      pkgs = legacyPackages.${system};
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
          inputs.stylix.nixosModules.stylix

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              backupFileExtension = "backup";

              users.${username} = {
                imports =
                  [
                    # ../hosts/${hostname}/home-manager
                    ../hosts/common/home-manager/nixos
                    # inputs.nix-doom-emacs.hmModule
                    inputs.spicetify-nix.homeManagerModule
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username colorscheme wallpaper; };

            };
          }
        ];
    };

  mkDarwinSystem =
    { hostname
    , legacyPackages
    , username ? "eyad"
    , colorscheme ? null
    , system

    }:
    darwinSystem {
      pkgs = legacyPackages.${system};
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

                    # ../hosts/${hostname}/home-manager
                    inputs.nix-doom-emacs.hmModule
                  ]
                  ++ attrValues (import ../modules/home-manager);
              };
              extraSpecialArgs = { inherit inputs outputs hostname username colorscheme; };
              backupFileExtension = "backup";
            };
          }
        ];
    };

  isDarwin = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];
  isLinux = system: builtins.elem system [ "x86_64-linux" ];

  stdenv.targetSystem = {
    isDarwinArm64 = stdenv.targetSystem.isDarwin && stdenv.targetSystem.darwinArch == "arm64";
  };

  nixConfig = {
    # allowUnfree = true;
    permittedInsecurePackages = [
      "electron-12.2.3"
      # "electron-13.6.9"
      # "electron-14.2.9"
      "electron-21.4.0"
      "electron-19.1.9"

    ];
    allowUnfree = true;

  };

  forAllSystems = genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "i686-linux"
  ];
  toGuest = builtins.replaceStrings [ "darwin" ] [ "linux" ];

  has = element: any (x: x == element);
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


}
