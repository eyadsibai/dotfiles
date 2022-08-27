{ inputs, ... }:
let
  inherit (inputs) self home-manager nixpkgs;
  inherit (self) outputs;

  inherit (builtins) elemAt match any mapAttrs attrValues attrNames listToAttrs;
  inherit (nixpkgs.lib) nixosSystem filterAttrs genAttrs mapAttrs' mapAttrsToList;
in
rec {
  # Applies a function to a attrset's names, while keeping the values
  mapAttrNames = f: mapAttrs' (name: value: { name = f name; inherit value; });

  has = element: any (x: x == element);

  mkSystem =
    { hostname
    , pkgs
    , persistence ? false
    }:
    nixosSystem {
      inherit pkgs;
      specialArgs = {
        inherit inputs outputs hostname persistence;
      };
      modules = attrValues (import ../modules/nixos) ++ [ ../hosts/${hostname} ];
    };

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
}
#https://github.com/archseer/snowflake/blob/master/lib/utils.nix can I move mergeEnvs here?
