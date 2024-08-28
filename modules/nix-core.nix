{
  config, pkgs,
  lib,
  ...
}: {
  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;  
  nix.settings.max-jobs = lib.mkDefault 32;  # Set this to the number of cores you have
  nix.settings.cores = lib.mkDefault 0; # Use all available cores
  nix.settings.sandbox = true;            # Ensure sandboxing is enabled for security and reliability
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
#  nixpkgs.config.cudaCapabilities = ["12.2" "12.3"];
  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.
  # nix.useDaemon = true;

 #  nix.package = pkgs.nixFlakes;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Disable auto-optimise-store because of this issue:
  #   https://github.com/NixOS/nix/issues/7273
  # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
  nix.settings = {
    auto-optimise-store = true;
    substituters = [
          "https://cache.nixos.org/"
          "https://cuda-maintainers.cachix.org"
          ];

          trusted-public-keys = [
                "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                ];
    
  };

}
