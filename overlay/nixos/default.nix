# This file defines two overlays and composes them
{ inputs
, lib
, ...
}:
let
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

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
                    #                     sha256 = prev.lib.fakeSha256;
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

              # propagatedBuildInputs = [ prev.ffmpeg ];
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
    };
in
inputs.nixpkgs.lib.composeManyExtensions [ additions modifications ]
