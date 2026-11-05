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

    # Omarchy's desktop packaged for NixOS. Follows main, which runs ahead of the
    # release tags; `just update` moves it along with everything else.
    nixarchy = {
      url = "github:olafkfreund/nixarchy";
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
            isArch = false;
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
            # TEMPORARY: nixos-unstable's opencode 2.2.5 has a wrong Linux node_modules
            # hash (fixed in nixpkgs master c399e1b7fb). Inert once the fix lands;
            # delete then.
            {
              nixpkgs.overlays = [
                (final: prev: {
                  opencode =
                    if
                      prev.opencode.node_modules.outputHash == "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc="
                    then
                      prev.opencode.overrideAttrs (old: {
                        node_modules = old.node_modules.overrideAttrs {
                          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
                        };
                      })
                    else
                      prev.opencode;
                })
              ];
            }
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
            isArch = false;
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

      # Omarchy on Arch: Home Manager on its own, the system stays pacman's
      mkArch =
        hostDir:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs username useremail;
            repoDir = "/home/${username}/dev/dotfiles";
            isArch = true;
          };
          modules = [
            ./modules/home/arch.nix
            hostDir
            nix-index-database.homeModules.nix-index
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

      homeConfigurations = {
        "${username}@vector" = mkArch ./hosts/vector; # Dell XPS 14, Omarchy on Arch
        "${username}@cachy" = mkArch ./hosts/cachy; # desktop, Omarchy on Arch
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
          vector = self.homeConfigurations."${username}@vector".activationPackage;
          cachy = self.homeConfigurations."${username}@cachy".activationPackage;
          formatting = pkgs.runCommand "check-formatting" { } ''
            cp -r ${self} src && chmod -R +w src && cd src
            ${pkgs.lib.getExe pkgs.nixfmt-tree} --ci --tree-root .
            touch $out
          '';
        };

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShellNoCC {
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
