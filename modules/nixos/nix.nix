{ repoDir, ... }:
{
  imports = [ ../common/nix.nix ];

  # nh: `nh os switch` (shows a package diff before activating) and
  # scheduled cleanup of old generations, replacing nix.gc
  programs.nh = {
    enable = true;
    flake = repoDir;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 10";
    };
  };
}
