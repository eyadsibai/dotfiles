{ config, pkgs, ... }:

let addons = pkgs.nur.repos.rycee.firefox-addons;
in {

  # Browsers
  programs.firefox = {
    enable = true;
    extensions = with addons; [
      ublock-origin
      vimium
      bitwarden
      buster-captcha-solver
      netflix-1080p
    ];

    profiles.default = {
      id = 0;
      name = "eyad";
      isDefault = true;
      bookmarks = { };
      settings = {
        "browser.startup.homepage" = "https://start.duckduckgo.com";
        "identity.fxaccounts.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "signon.rememberSignons" = false;
        "browser.topsites.blockedSponsors" = ''["amazon"]'';
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.disableResetPrompt" = true;
        "browser.uiCustomization.state" = ''
          {"placements":{"widget-overflow-fixed-list":["ublock0_raymondhill_net-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":17,"newElementCount":3}'';
      };
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
