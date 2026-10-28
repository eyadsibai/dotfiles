{ username, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    sandbox = true;
    # Up to 4 builds at once, 8 cores each: 32 threads in total, matching the CPU
    # (cores = 0 would let every one of the parallel builds use all 32)
    max-jobs = 4;
    cores = 8;
    # Keep build inputs around so dev shells survive garbage collection
    keep-outputs = true;
    keep-derivations = true;

    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      # Prebuilt cudaSupport packages (replaces the retired cuda-maintainers.cachix.org)
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # Deduplicate the store on a timer instead of during every build (auto-optimise-store)
  nix.optimise.automatic = true;

  # nh: `nh os switch` (shows a package diff before activating) and
  # scheduled cleanup of old generations, replacing nix.gc
  programs.nh = {
    enable = true;
    flake = "/home/${username}/dev/nixconfig-workstation";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 10";
    };
  };
}
