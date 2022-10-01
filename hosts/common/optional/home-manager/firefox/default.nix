{ lib
, config
, pkgs
, hostname
, ...
}:
let
  addons = pkgs.nur.repos.rycee.firefox-addons;
in
{
  home.packages = with pkgs; [ nur.repos.wolfangaukang.vdhcoapp ff2mpv ];
  # Browsers
  programs.firefox = {
    enable = true;
    package = lib.mkDefault (pkgs.wrapFirefox pkgs.firefox-unwrapped { forceWayland = false; });
    extensions = with addons; [
      ublock-origin
      vimium
      bitwarden
      # buster-captcha-solver
      netflix-1080p
      # betterttv
      h264ify
      # umatrix
      a11ycss
      # add-custom-search-engine
      # adnauseam
      # anonaddy
      # behave
      # auto-tab-discard
      # behind-the-overlay-revival
      # better-tweetdeck
      # betterttv
      # bukubrow
      bypass-paywalls-clean
      # clearurls
      # flagfox
      grammarly
      # search-by-image
      unpaywall
      # facebook-container
      # ff2mpv
      # floccus
      # fraidycat

      (
        buildFirefoxXpiAddon
          rec {
            pname = "Video-DownloadHelper";
            version = "7.6.0";
            addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
            url = "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-${version}-fx.xpi";
            sha256 = "sha256-vVHZwQZOhpogQDAS4BAxm0bvCrcrsz8ioxDdOqsnelM=";
            meta = { };
          }
      )
      (
        buildFirefoxXpiAddon
          rec {
            pname = "ticktick";
            version = "1.1.5.0";
            addonId = "{52198036-5173-4877-a8e8-62474781798d}";
            url = "https://addons.mozilla.org/firefox/downloads/file/3972098/ticktick_todo-${version}.xpi";
            sha256 = "sha256-wVczdaWzzuBC8DwqcFT4g/KkAK6UCfD0LjIHQMiettA=";
            meta = { };
          }
      )
      (
        buildFirefoxXpiAddon
          rec {
            pname = "leechblock-ng";
            version = "1.5.1";
            addonId = "leechblockng@proginosko.com";
            url = "https://addons.mozilla.org/firefox/downloads/file/3542788/leechblock_ng-${version}-an+fx.xpi?src=";
            sha256 = "sha256-d8K0vD+LpZ8xmKB8jX1Sjj4gTHNLLCZQAD4LT/rpUJE=";
            meta = { };
          }
      )
    ];
    profiles.eyad = {
      # id = 0;
      # name = "eyad";
      isDefault = true;
      bookmarks = { };
      settings = {
        "app.update.auto" = false;
        "browser.crashReports.unsubmittedCheck.enabled" = false;
        "browser.disableResetPrompt" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        # "browser.startup.homepage" = "https://start.duckduckgo.com";
        "browser.topsites.blockedSponsors" = ''["amazon"]'';
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

        "browser.safebrowsing.malware.enabled" = true;
        "browser.safebrowsing.phishing.enabled" = true;
        "device.sensors.enabled" = false;
        "dom.battery.enabled" = false;
        "dom.webaudio.enabled" = false;
        "experiments.enabled" = false;
        "experiments.supported" = false;
        "browser.uiCustomization.state" = ''
          {"placements":{"widget-overflow-fixed-list":["ublock0_raymondhill_net-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":17,"newElementCount":3}'';
        "browser.uidensity" = 1;
        "browser.bookmarks.showMobileBookmarks" = true;
        "browser.ctrlTab.recentlyUsedOrder" = false;
        "browser.proton.enabled" = true;
        "browser.newtabpage.enabled" = true;
        "browser.newtabpage.activity-stream.improvesearch.handoffToAwesomebar" =
          false;
        "browser.search.hiddenOneOffs" = "Google,Yahoo,Bing,Amazon.com,Twitter";
        "browser.search.region" = "US";
        "browser.search.suggest.enabled" = true;
        "browser.send_pings" = false;
        "browser.startup.homepage" = "https://lobste.rs";
        "dom.security.https_only_mode" = true;
        "identity.fxaccounts.enabled" = false;
        "security.ssl.errorReporting.automatic" = false;
        "services.sync.addons.ignoreUserEnabledChanges" = true;

        # Telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
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

        ## privacy
        "privacy.donottrackheader.enabled" = true;
        "privacy.donottrackheader.value" = 1;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
        "network.dns.disablePrefetch" = true;

        "browser.urlbar.placeholderName" = "…";
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.suggest.history" = true;

        "devtools.theme" = config.colorscheme.kind;

        # FIXME: use global font defaults
        "font.default.x-western" = "sans-serif";
        "font.name.monospace.x-western" = "PragmataPro";
        "font.name.sans-serif.x-western" = "IBM Plex Sans";
        "font.name.serif.x-western" = "IBM Plex Serif";
        "font.size.monospace.x-western" = 18;

        "identity.fxaccounts.account.device.name" = hostname;

        # CSS blur filter in v88+
        "layout.css.backdrop-filter.enabled" = true;

        "security.enterprise_roots.enabled" = true;
        "services.sync.declinedEngines" = "addons,prefs,creditcards,addresses,tabs,passwords";
        "services.sync.engine.addons" = false;
        "services.sync.engine.passwords" = false;
        "services.sync.engine.prefs" = false;
        "services.sync.engineStatusChanged.addons" = true;
        "services.sync.engineStatusChanged.prefs" = true;
        "signon.rememberSignons" = false;

        # https://developer.mozilla.org/en-US/docs/Web/CSS/-moz-context-properties
        "svg.context-properties.content.enabled" = true;

        # Enable custom stylesheets.
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        "gfx.webrender.compositor.force-enabled" = true;
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        "extensions.pocket.enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.ffvpx.enabled" = true;
        "media.navigator.mediadatadecoder_vpx_enabled" = true;
        "media.rdd-vpx.enabled" = false;
        "layers.acceleration.force-enabled" = false;
      };
    };
  };
}
