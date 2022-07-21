self: super: {
  whatsapp-for-linux = super.whatsapp-for-linux.overrideAttrs (drv: rec {
    version = "1.4.5";
    pname = "whatsapp-for-linux";
    src = super.fetchFromGitHub {
    owner = "eneshecan";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-TX6fMuhe6VHbhWJSsPM0iOV4CuCfULD5McJyHuTW4lI=";
  };

  });
}
