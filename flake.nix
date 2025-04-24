# /etc/nixos/flake.nix
{
  description = "flake for my workstation";

  inputs = {
    nixpkgs = {


      url = "github:NixOS/nixpkgs/nixos-unstable";
      # url = "github:NixOS/nixpkgs/nixos-24.11";


    };
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-index-database, ... }@inputs:
    let
      username = "eyad";
      useremail = "eyad.alsibai@gmail.com";
      system = "x86_64-linux";
      hostname = "workstation";
      specialArgs =
        inputs
        // {
          inherit username useremail hostname;
        };
    in
    {
      nixosConfigurations = {
        "${hostname}" = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            # Core system and user config
            ./modules/nix-core.nix
            ./modules/system.nix # Merged core, shell, starship HM config
            ./modules/host-users.nix

            # Desktop Environment (choose one)
            ./modules/desktop/gnome.nix
            # ./modules/desktop/hyprland.nix

            # Applications and Development
            ./modules/apps.nix
            ./modules/coding.nix # Merged git HM config
            ./modules/ai/default.nix # AI specific packages

            # Home Manager module itself
            inputs.home-manager.nixosModules.home-manager
            {
              # Configure HM options here if needed globally,
              # user-specific settings are now in respective modules.
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.extraSpecialArgs = specialArgs;
            }

            # Other modules
            inputs.nix-index-database.nixosModules.nix-index
            { programs.nix-index-database.comma.enable = true; }
          ];
        };
      };
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

    };
}
