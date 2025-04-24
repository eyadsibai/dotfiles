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
          modules = [ ./hosts/workstation ]; # Point to the host-specific configuration
        };
      };
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

    };
}
