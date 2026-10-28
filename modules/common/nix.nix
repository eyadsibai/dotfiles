# Nix settings shared by NixOS and macOS (nix-darwin) hosts
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Keep build inputs around so dev shells survive garbage collection
    keep-outputs = true;
    keep-derivations = true;

    substituters = [
      # Mirror of cache.nixos.org, tried first: the route to cache.nixos.org's CDN
      # caps each download at ~1 MB/s from home, the mirror does 3-4x that. Same
      # files, signed by the cache.nixos.org key, so nothing new is trusted.
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=30"
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Deduplicate the store on a timer instead of during every build (auto-optimise-store)
  nix.optimise.automatic = true;
}
