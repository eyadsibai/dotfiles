# This file defines two overlays and composes them
{ inputs, lib, ... }:
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

    apple-silicon = final: prev: lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
      # Add access to x86 packages system is running Apple Silicon
      pkgs-x86 = import inputs.nixpkgs {
        system = "x86_64-darwin";
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-12.2.3" "electron-13.6.9" ];
        };
      };
    };

    nix-index-database = final.runCommandLocal "nix-index-database" { } ''
      mkdir -p $out
      ln -s ${inputs.nix-index-database.legacyPackages.${prev.system}.database} $out/files
    '';
  };
in
inputs.nixpkgs.lib.composeManyExtensions [ additions modifications ]
