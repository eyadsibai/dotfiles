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

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
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

    # Omarchy's desktop packaged for NixOS. Follows main, which runs ahead of the
    # release tags; `just update` moves it along with everything else.
    nixarchy = {
      url = "github:olafkfreund/nixarchy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.sops-nix.follows = "sops-nix";
      inputs.nix-index-database.follows = "nix-index-database";
      inputs.nixos-hardware.follows = "nixos-hardware";
      inputs.disko.follows = "disko";
      # Hyprland comes from nixpkgs (modules/nixos/desktop.nix), so dedupe its nixpkgs
      # copy and the extra home-manager copies pulled by nixarchy's sub-flakes.
      inputs.hyprland.inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-skills.inputs.home-manager.follows = "home-manager";
      inputs.nixarchy-voice.inputs.home-manager.follows = "home-manager";
      inputs.zen-browser.inputs.home-manager.follows = "home-manager";
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
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = specialArgs;
      };

      mkNixos =
        hostDir:
        let
          specialArgs = {
            inherit inputs username useremail;
            hostname = baseNameOf hostDir;
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

      # Home Manager on its own, on a machine whose system another distribution owns
      mkHome =
        {
          system,
          isArch,
          base,
        }:
        hostDir:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit
              inputs
              username
              useremail
              isArch
              ;
            hostname = baseNameOf hostDir;
            repoDir = "/home/${username}/dev/dotfiles";
          };
          modules = [
            base
            hostDir
            nix-index-database.homeModules.nix-index
            { programs.nix-index-database.comma.enable = true; }
          ];
        };

      # Omarchy on Arch: the system and the programs stay pacman's
      mkArch = mkHome {
        system = "x86_64-linux";
        isArch = true;
        base = ./modules/home/arch.nix;
      };

      # Any other Linux: the system stays the distribution's, and Nix installs the
      # programs as it does on NixOS. The host file picks the shared modules it wants.
      mkLinux =
        system:
        mkHome {
          inherit system;
          isArch = false;
          base = ./modules/home/standalone.nix;
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
        "${username}@spark" = mkLinux "aarch64-linux" ./hosts/spark; # NVIDIA DGX Spark, Ubuntu
      };

      darwinConfigurations = {
        eyad-m3 = mkDarwin "eyad-m3";
        eyad-mac = mkDarwin "eyad-mac";
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # What `just check` and CI's eval matrix (.github/workflows/check.yml) evaluate,
      # without building: every configuration above, by the attribute whose derivation
      # proves it evaluates, and the homelab test. Both read this list, so a new host
      # is checked without being named anywhere else.
      evalTargets =
        map (name: "nixosConfigurations.${name}.config.system.build.toplevel") (
          lib.attrNames self.nixosConfigurations
        )
        ++ map (name: "darwinConfigurations.${name}.config.system.build.toplevel") (
          lib.attrNames self.darwinConfigurations
        )
        ++ map (name: ''homeConfigurations."${name}".activationPackage'') (
          lib.attrNames self.homeConfigurations
        )
        ++ [
          "checks.x86_64-linux.homelab"
          "checks.x86_64-linux.home-server-full-eval"
          "checks.x86_64-linux.arch-caches-sync"
        ];

      # Built to test something: `nix build .#checks.x86_64-linux.<name> -L`
      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          # Boots the homelab in a VM (tests/homelab.nix); CI runs it when the homelab
          # or the inputs change (.github/workflows/homelab.yml)
          homelab = import ./tests/homelab.nix {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              inherit overlays;
              config.allowUnfree = true;
            };
            inherit inputs username useremail;
          };
          # Evaluates home-server with every off-by-default stage turned on (domain,
          # secrets, VPN, backups, Samba shares, auth, SnapRAID disks, Secure Boot)
          # so nixpkgs option renames break CI before those stages are enabled for real.
          home-server-full-eval =
            (self.nixosConfigurations.home-server.extendModules {
              modules = [
                {
                  my.secureBoot.enable = true;
                  # Synthetic eval check: secrets/home-server.yaml doesn't exist yet.
                  sops.validateSopsFiles = false;
                  my.homelab = {
                    domain = "home.example.com";
                    acmeEmail = "test@example.com";
                    lanAddress = "192.168.8.10";
                    beszelKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI000000000000000000000000000000000000000000";
                    secrets = {
                      enable = true;
                      file = ./flake.nix;
                    };
                    vpn.enable = true;
                    backup.enable = true;
                    shares.enable = true;
                    apps.auth.enable = true;
                    storage = {
                      dataDisks.disk1 = "/dev/disk/by-id/dummy-disk1-part1";
                      parityDisks.parity1 = "/dev/disk/by-id/dummy-parity1-part1";
                    };
                  };
                }
              ];
            }).config.system.build.toplevel;
          # Keeps root-owned arch/nix.conf aligned with modules/common/caches.nix.
          arch-caches-sync =
            let
              caches = import ./modules/common/caches.nix;
              conf = builtins.readFile ./arch/nix.conf;
              expectedSubs = "substituters = ${lib.concatStringsSep " " caches.substituters}";
              expectedKeys = "trusted-public-keys = ${lib.concatStringsSep " " caches.trusted-public-keys}";
            in
            assert lib.assertMsg (lib.hasInfix expectedSubs conf)
              "arch/nix.conf substituters drifted from modules/common/caches.nix";
            assert lib.assertMsg (lib.hasInfix expectedKeys conf)
              "arch/nix.conf trusted-public-keys drifted from modules/common/caches.nix";
            pkgs.runCommand "arch-caches-sync" { } "touch $out";
          formatting = pkgs.runCommand "check-formatting" { } ''
            cp -r ${self} src && chmod -R +w src && cd src
            ${pkgs.lib.getExe pkgs.nixfmt-tree} --ci --tree-root .
            touch $out
          '';
        };

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShellNoCC {
          packages = with nixpkgs.legacyPackages.${system}; [
            bashInteractive # macOS ships Bash 3.2; repo scripts use Bash 4+
            nixfmt
            nixd
            statix
            deadnix
            shellcheck
            ruff
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
