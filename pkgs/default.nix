# Packages not in nixpkgs. overlays/default.nix adds them to pkgs (pkgs.coderabbit,
# pkgs.superwhisper) on every host, and flake.nix exposes them as `packages`, which CI builds.
pkgs: {
  coderabbit = pkgs.callPackage ./coderabbit.nix { };
  superwhisper = pkgs.callPackage ./superwhisper { };
}
