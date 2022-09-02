# This file defines two overlays and composes them
{ inputs
, lib
, ...
}:
let
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications =
    final:
    prev:
    {
      whatsapp-for-linux =
        prev.whatsapp-for-linux.overrideAttrs
          (
            oldAttrs:
            rec {
              version = "1.4.6";
              src =
                prev.fetchFromGitHub
                  {
                    owner = "eneshecan";
                    repo = "${ oldAttrs.pname }";
                    rev = "v${ version }";
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

      nix-index-database =
        final.runCommandLocal
          "nix-index-database"
          { }
          ''
            mkdir -p $out
            ln -s ${ inputs.nix-index-database.legacyPackages.${ prev.system }.database } $out/files
          '';

      # comma = prev.comma.overrideAttrs { pkgs = final; };
    };

  stable =
    self: super: {
      stable = import inputs.stable
        {
          system = super.stdenv.system;
          config = lib.nixConfig;
        };
    };
in
inputs.nixpkgs.lib.composeManyExtensions [ additions modifications stable ]
