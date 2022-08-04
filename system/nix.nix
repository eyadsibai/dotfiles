{ config, pkgs, ... }:
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


    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";

  };

}
