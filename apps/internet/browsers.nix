{ pkgs, ... }: {

  programs.firefox = {
    enable = true;
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      vimium
      bitwarden
      buster-captcha-solver
    ];

    profiles.default = {
      id = 0;
      name = "eyad";
      isDefault = true;
    };
  };

  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      {
        id = "dcpihecpambacapedldabdbpakmachpb";
        updateUrl =
          "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
      }
    ];
  };

  programs.librewolf = { enable = true; };

  programs.qutebrowser = { enable = true; };

}
