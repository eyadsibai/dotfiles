final: prev: {
  whatsapp-for-linux = prev.whatsapp-for-linux.overrideAttrs (_: rec {
    version = "1.4.5";
    pname = "whatsapp-for-linux";
    src = prev.fetchFromGitHub {
      owner = "eneshecan";
      repo = pname;

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
}
