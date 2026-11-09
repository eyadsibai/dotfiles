# Nix settings shared by NixOS and macOS (nix-darwin) hosts
{ repoDir, username, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    trusted-users = [ username ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Keep build inputs around so dev shells survive garbage collection
    keep-outputs = true;
    keep-derivations = true;

    inherit (import ./caches.nix) substituters trusted-public-keys;
  };

  # Deduplicate the store on a timer instead of during every build (auto-optimise-store)
  nix.optimise.automatic = true;

  # nh: `nh os switch` / `nh darwin switch` (shows a package diff before activating)
  # and scheduled cleanup of old generations, replacing nix.gc
  programs.nh = {
    enable = true;
    flake = repoDir;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 10";
    };
  };
}
