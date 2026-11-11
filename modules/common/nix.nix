# Nix settings shared by NixOS and macOS (nix-darwin) hosts
{ repoDir, username, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    # Lets me copy builds in unsigned, which `just deploy` needs to put a system
    # built here onto home-server. That makes anything running as me able to get
    # root without sudo's approval. Kept: only my SSH keys log in as me, and the
    # alternative is signing every build with a key the server trusts.
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
