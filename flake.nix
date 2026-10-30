{
  description = "NixOS and macOS configurations for all my machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Omarchy's desktop packaged for NixOS. Pinned to a release tag: bump on
    # purpose, after the Arch machines are on the same Omarchy version.
    nixarchy = {
      url = "github:olafkfreund/nixarchy/v4.5.0-rc2-1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.sops-nix.follows = "sops-nix";
      inputs.nix-index-database.follows = "nix-index-database";
      inputs.nixos-hardware.follows = "nixos-hardware";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-index-database,
      sops-nix,
      ...
    }@inputs:
    let
      username = "eyad";
      useremail = "eyad.alsibai@gmail.com";

      # Settings every host's Home Manager shares
      homeManagerDefaults = specialArgs: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "bak";
        home-manager.extraSpecialArgs = specialArgs;
      };

      mkNixos =
        hostDir:
        let
          specialArgs = {
            inherit inputs username useremail;
            repoDir = "/home/${username}/dev/dotfiles";
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            hostDir
            home-manager.nixosModules.home-manager
            (homeManagerDefaults specialArgs)
            nix-index-database.nixosModules.nix-index
            { programs.nix-index-database.comma.enable = true; }
            sops-nix.nixosModules.sops
          ];
        };

      # Every Mac gets the same configuration; only the name differs
      mkDarwin =
        hostname:
        let
          specialArgs = {
            inherit
              inputs
              username
              useremail
              hostname
              ;
            repoDir = "/Users/${username}/dev/dotfiles";
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          modules = [
            ./hosts/mac
            home-manager.darwinModules.home-manager
            (homeManagerDefaults specialArgs)
            nix-index-database.darwinModules.nix-index
            { programs.nix-index-database.comma.enable = true; }
          ];
        };

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      nixosConfigurations = {
        workstation = mkNixos ./hosts/workstation; # Intel + RTX 4090 desktop
        eyad-nixos = mkNixos ./hosts/eyad-nixos; # AMD ThinkPad
        home-server = mkNixos ./hosts/home-server; # future Unraid replacement (skeleton)
      };

      darwinConfigurations = {
        eyad-m3 = mkDarwin "eyad-m3";
        eyad-mac = mkDarwin "eyad-mac";
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # `nix flake check` builds these; CI runs it with --no-build (evaluation only)
      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          workstation = self.nixosConfigurations.workstation.config.system.build.toplevel;
          eyad-nixos = self.nixosConfigurations.eyad-nixos.config.system.build.toplevel;
          formatting = pkgs.runCommand "check-formatting" { } ''
            cp -r ${self} src && chmod -R +w src && cd src
            ${pkgs.lib.getExe pkgs.nixfmt-tree} --ci --tree-root .
            touch $out
          '';
        };

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            nixfmt
            nixd
            just
            nh
            sops
            age
            ssh-to-age
          ];
        };
      });
    };
}
