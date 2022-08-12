{
  lib,
  config,
  pkgs,
  ...
}: let
  addons = pkgs.nur.repos.rycee.firefox-addons;
in {
  home.packages = with pkgs; [nur.repos.wolfangaukang.vdhcoapp ff2mpv];
  # Browsers
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      forceWayland = false;
    };
    extensions = with addons; [
      ublock-origin
      vimium
      bitwarden
      buster-captcha-solver
      netflix-1080p
      betterttv
      h264ify
      umatrix
      a11ycss
      add-custom-search-engine
      adnauseam
      anonaddy
      behave
      auto-tab-discard
      behind-the-overlay-revival
      better-tweetdeck
      betterttv
      bukubrow
      bypass-paywalls-clean
      clearurls
      flagfox
      grammarly
      search-by-image
      unpaywall
      facebook-container
      ff2mpv
      floccus
      fraidycat
      (buildFirefoxXpiAddon rec {
        pname = "Video-DownloadHelper";
        version = "7.6.0";
        addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
        url = "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-${version}-fx.xpi";
        sha256 = "sha256-vVHZwQZOhpogQDAS4BAxm0bvCrcrsz8ioxDdOqsnelM=";
        meta = {};
      })
      (buildFirefoxXpiAddon rec {
        pname = "ticktick";
        version = "1.1.5.0";
        addonId = "{52198036-5173-4877-a8e8-62474781798d}";
        url = "https://addons.mozilla.org/firefox/downloads/file/3972098/ticktick_todo-${version}.xpi";
        sha256 = "sha256-wVczdaWzzuBC8DwqcFT4g/KkAK6UCfD0LjIHQMiettA=";
        meta = {};
      })
    ];

    profiles."eyad" = {
      # id = 0;
      # name = "eyad";
      isDefault = true;
      bookmarks = {};
      settings = {
        "app.update.auto" = false;
        "browser.crashReports.unsubmittedCheck.enabled" = false;
        "browser.disableResetPrompt" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.startup.homepage" = "https://start.duckduckgo.com";
        "browser.topsites.blockedSponsors" = ''["amazon"]'';
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "browser.safebrowsing.malware.enabled" = true;
        "browser.safebrowsing.phishing.enabled" = true;
        "browser.send_pings" = false;
        "device.sensors.enabled" = false;
        "dom.battery.enabled" = false;
        "dom.webaudio.enabled" = false;
        "experiments.enabled" = false;
        "experiments.supported" = false;
        "browser.uiCustomization.state" = ''
          {"placements":{"widget-overflow-fixed-list":["ublock0_raymondhill_net-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":17,"newElementCount":3}'';
        "dom.security.https_only_mode" = true;
        "identity.fxaccounts.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "signon.rememberSignons" = false;
        "security.ssl.errorReporting.automatic" = false;
        "services.sync.engine.addons" = false;
        "services.sync.addons.ignoreUserEnabledChanges" = true;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.hybridContent.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "gfx.webrender.compositor.force-enabled" = true;
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        "extensions.pocket.enabled" = false;

        "media.ffmpeg.vaapi.enabled" = true;
        "media.ffvpx.enabled" = false;
        "media.navigator.mediadatadecoder_vpx_enabled" = true;
        "media.rdd-vpx.enabled" = false;
      };
    };
  };
}
