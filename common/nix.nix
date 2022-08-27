{ inputs, pkgs, lib, config, ... }:
{
  environment.systemPackages = with pkgs; [ cachix ];

  nix = {
    package = pkgs.nixFlakes;
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${ key }=${ value.to.path }") config.nix.registry;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings =
      {

        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
          "https://shawn8901.cachix.org"
          "https://eyadsibai.cachix.org"
          "https://danth.cachix.org"
          "https://helix.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "shawn8901.cachix.org-1:7RAYBGET4e+szLrg86T9PP1vwDp+T99Fq0sTDt3B2DA="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "eyadsibai.cachix.org-1:7+k2Qd+uu7AGrS1AvO59mZJWn6PIvQAXK4EzAlqTSLA="
          "danth.cachix.org-1:wpodfSL7suXRc/rJDZZUptMa1t4MJ795hemRN0q84vI="
          "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        ];

        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        warn-dirty = false;
      };


  };
}
