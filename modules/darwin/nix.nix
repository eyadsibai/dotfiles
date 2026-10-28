{ repoDir, username, ... }:
{
  imports = [ ../common/nix.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings = {
    extra-platforms = "x86_64-darwin aarch64-darwin"; # Rosetta 2
    trusted-users = [ username ];
  };

  # Nix was installed before nix-darwin moved the nixbld group to 350
  ids.gids.nixbld = 30000;

  # Builds Linux derivations (e.g. the NixOS hosts) in a small VM
  nix.linux-builder.enable = true;

  # `nh darwin switch` plus scheduled cleanup of old generations, as on NixOS
  programs.nh = {
    enable = true;
    flake = repoDir;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 10";
    };
  };
}
