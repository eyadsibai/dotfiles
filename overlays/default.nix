# Overlays applied on every host (NixOS, macOS and the Arch Home Manager configs).
{
  # pkgs/ as pkgs.<name>
  additions = final: _prev: import ../pkgs final;

  # Fixes to nixpkgs packages. Each says when it can go; patches sit beside this file.
  modifications = final: prev: {
    # voxtype 1.1.1 (Omarchy's dictation) doesn't build on nixos-unstable (f4a03c0): the
    # cargo setup hook now makes every Rust package link system libraries instead of
    # vendored ones, and its libsqlite3-sys finds no sqlite among its inputs
    # (`cannot find -lsqlite3`). Inert once nixpkgs adds sqlite to voxtype; delete then.
    voxtype =
      if prev.lib.any (p: (p.pname or "") == "sqlite") (prev.voxtype.buildInputs or [ ]) then
        prev.voxtype
      else
        prev.voxtype.overrideAttrs (old: {
          buildInputs = old.buildInputs or [ ] ++ [ final.sqlite ];
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
