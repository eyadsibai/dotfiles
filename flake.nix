{
  description = "My Ultimate Flake";
  inputs = {
    unstable.url = "nixpkgs/nixos-unstable";
    bleeding-edge.url = "nixpkgs/master";
    stable.url = "nixpkgs/nixos-22.05";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:Mic92/nix-index-database";

    home-manager = {
      # url = "github:nix-community/home-manager/release-22.11";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    flake-utils.url = "github:numtide/flake-utils";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    mach-nix.url = "github:DavHau/mach-nix";
    firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    eww.url = "github:elkowar/eww";

    mpv-iptv = {
      url = "github:junners/mpv-iptv";
      flake = false;
    };

    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";
    base16 = {
      url = "github:SenchoPens/base16.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spacebar = {
      url = "github:cmacrae/spacebar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yabai-src = {
      url = "github:koekeishiya/yabai";
      flake = false;
    };
    spicetify-nix = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    polybar-themes = {
      url = "github:adi1090x/polybar-themes";
      flake = false;
    };

    flake-utils-plus = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
    };
    macos-builder.url = "github:Gabriella439/macos-builder";

  };
  outputs = inputs:
    let
      lib = import ./lib { inherit inputs; };
      inherit (lib) forAllSystems mkNixOSSystem mkVMNixOSSystem mkDarwinSystem mergeEnvs nixConfig toGuest;
      overlays = {
        default = import ./overlay { inherit inputs lib; };
        nur = inputs.nur.overlay;
        neovim = inputs.neovim-nightly-overlay.overlay;
        poetry2nix = inputs.poetry2nix.overlay;
        spacebar = inputs.spacebar.overlay;
        nixpkgs-wayland = inputs.nixpkgs-wayland.overlay;
        nixgl = inputs.nixgl.overlay;
        # comma = (inputs.flake-utils-plus.lib.genPkgOverlay inputs.comma "comma");
        # comma = inputs.comma.overlays.default;
      };

      legacyPackages =
        forAllSystems
          (system:
            import
              inputs.nixpkgs
              {
                inherit system;
                overlays = builtins.attrValues overlays;
                config = nixConfig;
              }
          );
    in
    rec {
      inherit lib;
      inherit overlays;
      inherit legacyPackages;

      templates = import ./templates;

      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      homeManagerModules = import ./modules/home-manager;

      devShells =
        forAllSystems
          (
            system:
            let
              pkgs = legacyPackages.${system};
            in
            rec {
              default = pkgs.callPackage ./shell.nix { };
              bluetooth = import ./shells/penetration/bluetooth.nix { inherit pkgs; };
              code = import ./shells/penetration/code.nix { inherit pkgs; };
              container = import ./shells/penetration/container.nix { inherit pkgs; };
              dns = import ./shells/penetration/dns.nix { inherit pkgs; };
              forensics = import ./shells/penetration/forensics.nix { inherit pkgs; };
              fuzzers = import ./shells/penetration/fuzzers.nix { inherit pkgs; };
              generic = import ./shells/penetration/generic.nix { inherit pkgs; };
              hardware = import ./shells/penetration/hardware.nix { inherit pkgs; };
              host = import ./shells/penetration/host.nix { inherit pkgs; };
              information-gathering = import ./shells/penetration/information-gathering.nix { inherit pkgs; };
              kubernetes = import ./shells/penetration/kubernetes.nix { inherit pkgs; };
              ldap = import ./shells/penetration/ldap.nix { inherit pkgs; };
              load-testing = import ./shells/penetration/load-testing.nix { inherit pkgs; };
              malware = import ./shells/penetration/malware.nix { inherit pkgs; };
              misc = import ./shells/penetration/misc.nix { inherit pkgs; };
              mobile = import ./shells/penetration/mobile.nix { inherit pkgs; };
              network = import ./shells/penetration/network.nix { inherit pkgs; };
              packet-generators = import ./shells/penetration/packet-generators.nix { inherit pkgs; };
              password = import ./shells/penetration/password.nix { inherit pkgs; };
              port-scanners = import ./shells/penetration/port-scanners.nix { inherit pkgs; };
              proxies = import ./shells/penetration/proxies.nix { inherit pkgs; };
              services = import ./shells/penetration/services.nix { inherit pkgs; };
              smartcards = import ./shells/penetration/smartcards.nix { inherit pkgs; };
              terminals = import ./shells/penetration/terminals.nix { inherit pkgs; };
              traffic = import ./shells/penetration/traffic.nix { inherit pkgs; };
              tunneling = import ./shells/penetration/tunneling.nix { inherit pkgs; };
              voip = import ./shells/penetration/voip.nix { inherit pkgs; };
              web = import ./shells/penetration/web.nix { inherit pkgs; };
              windows = import ./shells/penetration/windows.nix { inherit pkgs; };
              wireless = import ./shells/penetration/wireless.nix { inherit pkgs; };
              penetration-full = mergeEnvs { inherit pkgs; } [
                bluetooth
                code
                container
                dns
                forensics
                fuzzers
                generic
                hardware
                host
                information-gathering
                kubernetes
                ldap
                load-testing
                malware
                misc
                mobile
                network
                packet-generators
                password
                port-scanners
                proxies
                services
                smartcards
                terminals
                traffic
                tunneling
                voip
                web
                windows
                wireless
              ];
            }
          );


      darwinConfigurations = {
        "eyad-mac" =
          mkDarwinSystem {
            hostname = "eyad-mac";
            system = "aarch64-darwin";
            legacyPkgs = legacyPackages;
            colorscheme = "tokyo-night-storm";
          };
      };

      nixosConfigurations = {
        "home-server" =
          mkNixOSSystem {
            hostname = "home-server";
            system = "x86_64-linux";
            legacyPkgs = legacyPackages;
          };
        "desktop-nixos-wsl" =
          mkNixOSSystem {
            hostname = "desktop-nixos-wsl";
            system = "x86_64-linux";
            legacyPkgs = legacyPackages;

            is-wsl = true;
          };

        "eyad-nixos" =
          mkNixOSSystem {
            hostname = "eyad-nixos";
            system = "x86_64-linux";
            legacyPkgs = legacyPackages;
            is-laptop = true;
            colorscheme = "tokyo-night-storm";
            wallpaper = "aurora-borealis-water-mountain";
          };

        "vm-linux-aarch64-darwin" = mkVMNixOSSystem {
          hostname = "vm-linux-aarch64-darwin";
          guest-system = "aarch64-linux";
          host-system = "aarch64-darwin";
          legacyPkgs = legacyPackages;
        };

      };

    };
}
