{ config, pkgs, lib, ... }:
{

  environment.systemPackages = with pkgs; [
    cachix
  ];

  nix = {
    # Automate garbage collection
    gc = {
      automatic = false;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    package = pkgs.nixFlakes;


    settings = {
      auto-optimise-store = true;
      extra-experimental-features = [ "nix-command" "flakes" ];
      cores = lib.mkDefault 8;
      max-jobs = lib.mkDefault 8;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://shawn8901.cachix.org"
        "https://eyadsibai.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "shawn8901.cachix.org-1:7RAYBGET4e+szLrg86T9PP1vwDp+T99Fq0sTDt3B2DA="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "eyadsibai.cachix.org-1:7+k2Qd+uu7AGrS1AvO59mZJWn6PIvQAXK4EzAlqTSLA="
      ];
      trusted-users = [ "root" "eyad" ];
    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";

  };

}
