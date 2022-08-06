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
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "shawn8901.cachix.org-1:7RAYBGET4e+szLrg86T9PP1vwDp+T99Fq0sTDt3B2DA="
      ];

    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";

  };

}
