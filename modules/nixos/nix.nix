{ username, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    sandbox = true;
    # Up to 16 builds at once, 8 cores each. Most builds are tiny (config files,
    # wrappers), so many in parallel keeps the 32 threads busy; the rare big
    # compiles running together can oversubscribe, which 125 GB of RAM absorbs
    max-jobs = 16;
    cores = 8;
    # Keep build inputs around so dev shells survive garbage collection
    keep-outputs = true;
    keep-derivations = true;

    substituters = [
      # Mirror of cache.nixos.org, tried first: the route to cache.nixos.org's CDN
      # caps each download at ~1 MB/s here, the mirror does 3-4x that. Same files,
      # signed by the cache.nixos.org key, so nothing new is trusted.
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=30"
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
