# Packages not in nixpkgs. overlays/default.nix adds them to pkgs (pkgs.coderabbit,
# pkgs.hype, ...) on every host, and flake.nix exposes them as `packages`, which CI builds.
pkgs: {
  coderabbit = pkgs.callPackage ./coderabbit.nix { };
  disktree = pkgs.callPackage ./disktree.nix { };
  superwhisper = pkgs.callPackage ./superwhisper { };
  inherit (pkgs.callPackage ./omacom-apps.nix { }) hype monologue signed;
}
