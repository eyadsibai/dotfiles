# Overlays applied on every host (NixOS, macOS and the Arch Home Manager configs).
{
  # pkgs/ as pkgs.<name>
  additions = final: _prev: import ../pkgs final;

  # Fixes to nixpkgs packages. Each says when it can go; patches sit beside this file.
  modifications = final: prev: {
    # codex 0.167.0 doesn't build on nixos-unstable (f4a03c0): the cargo setup hook
    # now makes every Rust package link system libraries instead of vendored ones
    # (AWS_LC_SYS_USE_SYSTEM=1 and the like), and five of codex's crates (aws-lc-sys,
    # zstd-sys, onig_sys, libsqlite3-sys, tikv-jemalloc-sys) find no such library
    # among its inputs. Give it all five, as other Rust packages in nixpkgs do.
    # Inert once nixpkgs adds aws-lc to codex; delete then.
    codex =
      if prev.lib.any (p: (p.pname or "") == "aws-lc") (prev.codex.buildInputs or [ ]) then
        prev.codex
      else
        prev.codex.overrideAttrs (old: {
          buildInputs = old.buildInputs or [ ] ++ [
            final.aws-lc
            final.zstd
            final.oniguruma
            final.sqlite
            final.rust-jemalloc-sys
          ];
        });

    # nixos-unstable's opencode 2.2.5 has a wrong Linux node_modules hash (fixed in
    # nixpkgs master c399e1b7fb). Inert once the fix lands; delete then.
    opencode =
      if
        prev.opencode.node_modules.outputHash or null
        == "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc="
      then
        prev.opencode.overrideAttrs (old: {
          node_modules = old.node_modules.overrideAttrs {
            outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
          };
        })
      else
        prev.opencode;
  };
}
