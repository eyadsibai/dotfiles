# This file defines two overlays and composes them
{ inputs
, lib
, ...
}:
let
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    whatsapp-for-linux =
      prev.whatsapp-for-linux.overrideAttrs
        (
          oldAttrs: rec {
            version = "1.4.6";
            src =
              prev.fetchFromGitHub
                {
                  owner = "eneshecan";
                  repo = "${oldAttrs.pname}";
                  rev = "v${version}";
                  # sha256 = prev.lib.fakeSha256;
                  # sha256 = "0000000000000000000000000000000000000000000000000000";
                  sha256 = "sha256-fpLjdEgglbc9kMHTGEPq7+UDB2Qh5e54l8mDOls79LA=";
                };
            buildInputs = [
              prev.glib-networking
              prev.gtkmm3
              prev.libayatana-appindicator
              prev.webkitgtk
              prev.gst_all_1.gst-libav
              prev.gst_all_1.gst-plugins-bad
              prev.gst_all_1.gst-plugins-base
              prev.gst_all_1.gst-plugins-good
            ];
          }
        );

    # caprine-bin =
    #   prev.caprine-bin.overrideAttrs
    #     (
    #       oldAttrs: rec {
    #         version = "2.56.1";
    #         passthru.x86_64-appimage = oldAttrs.passthru.x86_64-appimage.overrideAttrs
    #           (
    #             oldAttrs_appimage: rec {
    #               version = "2.56.1";
    #               # pname = "${oldAttrs_appimage.pname}";
    #               sha256 = prev.lib.fakeSha256;

    #             }
    #           );
    #       }
    #     );

    nix-index-database =
      final.runCommandLocal
        "nix-index-database"
        { }
        ''
          mkdir -p $out
          ln -s ${inputs.nix-index-database.legacyPackages.${prev.system}.database} $out/files
        '';

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

    # comma = prev.comma.overrideAttrs { pkgs = final; };
  };

  additions_inside = self: super: {
    stable =
      import inputs.stable
        {
          system = super.stdenv.system;
          config = lib.nixConfig;
        };

    bleeding-edge =
      import inputs.bleeding-edge
        {
          system = super.stdenv.system;
          config = lib.nixConfig;
        };

    apple-silicon-86x =
      import inputs.nixpkgs
        {
          system = "x86_64-darwin";
          config = lib.nixConfig;
          # overlays = [inputs.firefox-darwin.overlay];
        };

    firefox-darwin =
      import inputs.nixpkgs
        {
          system = super.stdenv.system;
          config = lib.nixConfig;
          overlays = [ inputs.firefox-darwin.overlay ];
        };
    #      );
  };
  # if you want to overrid certain packages
  # apple-silicon = self: super: (lib.optionalAttrs
  #   (super.stdenv.system == "aarch64-darwin")
  #   {
  #     inherit (import inputs.nixpkgs
  #       {
  #         system = "x86_64-darwin";
  #         config = lib.nixConfig;
  #       })
  #       # idris2
  #       nix-index
  #       ;
  #   });
in
inputs.nixpkgs.lib.composeManyExtensions [ additions modifications additions_inside ]
