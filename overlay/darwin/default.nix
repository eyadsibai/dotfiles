# This file defines two overlays and composes them
{ inputs
, lib
, nixConfig
, ...
}:
let
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs { pkgs = final; };
  apple-silicon = self: super: (inputs.nixpkgs.lib.optionalAttrs
    (super.stdenv.system == "aarch64-darwin")
    {
      inherit (import inputs.nixpkgs
        {
          system = "x86_64-darwin";
          config = nixConfig;
        })
        idris2
        nix-index
        ;
    });

in
inputs.nixpkgs.lib.composeManyExtensions [ apple-silicon ]
