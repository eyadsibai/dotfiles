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

    # Disk layout for the Mac VMs, which nixos-anywhere partitions at install
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # direnv in the background, so a slow .envrc doesn't hold up the prompt
    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-server: a root that starts empty on every boot, and Secure Boot
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # home-server: qBittorrent in a network namespace that only reaches the internet
    # through WireGuard (modules/nixos/homelab/downloads.nix). No inputs of its own.
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";

    # Self-hosted CI on the workstation, parked (modules/nixos/ci/nixbot.nix, docs/ci.md)
    # nixbot = {
    #   url = "github:Mic92/nixbot";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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
      inherit (nixpkgs) lib;
      username = "eyad";
      useremail = "eyad.alsibai@gmail.com";

      # pkgs/ as pkgs.<name>, plus fixes to nixpkgs (overlays/default.nix)
      overlays = builtins.attrValues self.overlays;

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
            { nixpkgs.overlays = overlays; }
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
            { nixpkgs.overlays = overlays; }
          ];
        };

      # Omarchy on Arch: Home Manager on its own, the system stays pacman's
      mkArch =
        hostDir:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            inherit overlays;
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

      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      overlays = import ./overlays;

      # pkgs/, for each system it builds on: `nix build .#coderabbit`; CI builds them
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
        in
        lib.filterAttrs (_: lib.meta.availableOn pkgs.stdenv.hostPlatform) (import ./pkgs pkgs)
      );

      nixosConfigurations = {
        workstation = mkNixos ./hosts/workstation; # Intel + RTX 4090 desktop
        eyad-nixos = mkNixos ./hosts/eyad-nixos; # AMD ThinkPad
        home-server = mkNixos ./hosts/home-server; # Unraid replacement, not installed yet
        vm-fusion = mkNixos ./hosts/vm-fusion; # desktop VM on the Macs, VMware Fusion
        vm-utm = mkNixos ./hosts/vm-utm; # desktop VM on the Macs, UTM
      };

      homeConfigurations = {
        "${username}@vector" = mkArch ./hosts/vector; # Dell XPS 14, Omarchy on Arch
        "${username}@cachy" = mkArch ./hosts/cachy; # desktop, Omarchy on Arch
      };

      darwinConfigurations = {
        eyad-m3 = mkDarwin "eyad-m3";
        eyad-mac = mkDarwin "eyad-mac";
      };

      # What the self-hosted CI builds (nixbot.toml; modules/nixos/ci/nixbot.nix)
      ciJobs = {
        hosts = lib.mapAttrs (_: c: c.config.system.build.toplevel) self.nixosConfigurations;
        homes = lib.mapAttrs (_: c: c.activationPackage) self.homeConfigurations;
        pkgs = self.packages.x86_64-linux;
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
          home-server = self.nixosConfigurations.home-server.config.system.build.toplevel;
          # Boots the homelab in a VM (tests/homelab.nix)
          homelab = import ./tests/homelab.nix {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              inherit overlays;
              config.allowUnfree = true;
            };
            inherit inputs username useremail;
          };
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
            nixos-anywhere # `just vm-install`
            nh
            sops
            age
            ssh-to-age
          ];
        };
      });
    };
}
