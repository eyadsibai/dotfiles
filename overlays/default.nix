# Overlays applied on every host (NixOS, macOS and the Arch Home Manager configs).
{
  # pkgs/ as pkgs.<name>
  additions = final: _prev: import ../pkgs final;

  # Fixes to nixpkgs packages. Each says when it can go; patches sit beside this file.
  modifications = _final: prev: {
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
