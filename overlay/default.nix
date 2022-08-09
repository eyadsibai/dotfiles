# This file defines two overlays and composes them
{ inputs, ... }:
let
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    whatsapp-for-linux = prev.whatsapp-for-linux.overrideAttrs (oldAttrs: rec {
    version = "1.4.5";
    src = prev.fetchFromGitHub {
      owner = "eneshecan";
      repo = "${oldAttrs.pname}";

      rev = "v${version}";
      # sha265 = lib.fakeSha256;
      # sha256 = "0000000000000000000000000000000000000000000000000000";
      sha256 = "V1QxPN99BAEnBvrfHyml0OsaS8msZXjkzvzItLqf8B0=";
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
    });
  };
in
inputs.nixpkgs.lib.composeManyExtensions [ additions modifications ]
