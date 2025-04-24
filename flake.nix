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

    # Darwin / macOS support
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim (used in Darwin config, potentially useful for Linux too)
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linux Desktop Specific (Keep if needed for Hyprland)
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, nixvim, nix-index-database, ... }@inputs: # Add darwin, nixvim
    let
      username = "eyad";
      useremail = "eyad.alsibai@gmail.com";

      # Define systems
      nixosSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin"; # Adjust if your Mac is Intel (x86_64-darwin)

      # Helper function to generate specialArgs for each system
      mkSpecialArgs = system: inputs // {
        inherit username useremail nixvim;
        # Add system-specific args if needed later
      };

      # Define hosts
      linuxHost = { hostname = "workstation"; system = nixosSystem; };
      macHost = { hostname = "macbook"; system = darwinSystem; }; # Placeholder hostname

    in
    {
      # NixOS Configurations (Linux)
      nixosConfigurations."${linuxHost.hostname}" = nixpkgs.lib.nixosSystem {
        system = linuxHost.system;
        specialArgs = mkSpecialArgs linuxHost.system // { hostname = linuxHost.hostname; };
        modules = [ ./hosts/workstation ]; # Point to the NixOS host config
      };

      # Darwin Configurations (macOS)
      darwinConfigurations."${macHost.hostname}" = darwin.lib.darwinSystem {
        system = macHost.system;
        specialArgs = mkSpecialArgs macHost.system // { hostname = macHost.hostname; };
        modules = [ ./hosts/macbook ]; # Point to the Darwin host config (to be created)
      };

      # Formatters for both systems
      formatter."${nixosSystem}" = nixpkgs.legacyPackages."${nixosSystem}".alejandra; # Use Alejandra for consistency
      formatter."${darwinSystem}" = nixpkgs.legacyPackages."${darwinSystem}".alejandra;
    };
}
