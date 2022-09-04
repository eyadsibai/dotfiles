# This file defines two overlays and composes them
{ inputs
, lib
, ...
}:
let
  modifications =
    final:
    prev:
    {
      yabai =
        let
          version = "4.0.0-dev";
          buildSymlinks = prev.runCommand "build-symlinks" { } ''
            mkdir -p $out/bin
            ln -s /usr/bin/xcrun /usr/bin/xcodebuild /usr/bin/tiffutil /usr/bin/qlmanage $out/bin
          '';
        in
        prev.yabai.overrideAttrs (old: {
          inherit version;
          src = inputs.yabai-src;

          buildInputs = with prev.darwin.apple_sdk.frameworks; [
            Carbon
            Cocoa
            ScriptingBridge
            prev.xxd
            SkyLight
          ];

          nativeBuildInputs = [ buildSymlinks ];
        });
    };
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs { pkgs = final; };
  apple-silicon = self: super: (inputs.nixpkgs.lib.optionalAttrs
    (super.stdenv.system == "aarch64-darwin")
    {
      inherit (import inputs.nixpkgs
        {
          system = "x86_64-darwin";
          config = lib.nixConfig;
        })
        # idris2
        nix-index
        ;
    });

in
inputs.nixpkgs.lib.composeManyExtensions [ modifications apple-silicon ]
