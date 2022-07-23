final: prev: {
  whatsapp-for-linux = prev.whatsapp-for-linux.overrideAttrs (_: rec {
    version = "1.4.5";
    pname = "whatsapp-for-linux";
    src = prev.fetchFromGitHub {
      owner = "eneshecan";
      repo = pname;

      rev = "v${version}";
      # sha256 = "0000000000000000000000000000000000000000000000000000";
      sha256 = "V1QxPN99BAEnBvrfHyml0OsaS8msZXjkzvzItLqf8B0=";
    };

    buildInputs = [

      prev.gtkmm3
      prev.libayatana-appindicator
      prev.webkitgtk
    ];
  });
}

