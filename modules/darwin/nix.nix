{
  imports = [ ../common/nix.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.extra-platforms = "x86_64-darwin aarch64-darwin"; # Rosetta 2

  # Nix was installed before nix-darwin moved the nixbld group to 350
  ids.gids.nixbld = 30000;

  # Builds Linux derivations (e.g. the NixOS hosts) in a small VM
  nix.linux-builder.enable = true;
}
