{
  description = "NixOS configuration for workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-index-database,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      specialArgs = {
        inherit inputs;
        username = "eyad";
        useremail = "eyad.alsibai@gmail.com";
      };
    in
    {
      nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/workstation
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.extraSpecialArgs = specialArgs;
          }
          nix-index-database.nixosModules.nix-index
          { programs.nix-index-database.comma.enable = true; }
          sops-nix.nixosModules.sops
        ];
      };

      formatter.${system} = pkgs.nixfmt-tree;

      # `nix flake check` builds these; CI runs it with --no-build (evaluation only)
      checks.${system} = {
        workstation = self.nixosConfigurations.workstation.config.system.build.toplevel;
        formatting = pkgs.runCommand "check-formatting" { } ''
          cp -r ${self} src && chmod -R +w src && cd src
          ${pkgs.lib.getExe pkgs.nixfmt-tree} --ci --tree-root .
          touch $out
        '';
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt
          nixd
          just
          nh
          sops
          age
          ssh-to-age
        ];
      };
    };
}
