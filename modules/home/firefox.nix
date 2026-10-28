# Firefox, ported from the old dotfiles flake: its extensions (installed through
# Firefox's own policies, from addons.mozilla.org) and its privacy, telemetry and
# UI preferences. Obsolete prefs from then (Pocket, Proton, experiments.*) are gone.
{ lib, pkgs, ... }:
let
  # addons.mozilla.org slug -> add-on ID
  extensions = {
    "ublock-origin" = "uBlock0@raymondhill.net";
    "vimium-ff" = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
    "1password-x-password-manager" = "{d634138d-c276-4fc8-924b-40a0ea21d284}";
    "bitwarden-password-manager" = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
    "h264ify" = "jid1-TSgSxBhncsPBWQ@jetpack";
    "a11ycss" = "a11y.css@ffoodd";
    "grammarly-1" = "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack";
    "unpaywall" = "{f209234a-76f0-4735-9920-eb62507a54cd}";
    "video-downloadhelper" = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
    "leechblock-ng" = "leechblockng@proginosko.com";
  };
in
{
  programs.firefox = {
    enable = true;
    # Where the existing profiles live (newer Home Manager defaults to ~/.config/mozilla)
    configPath = ".mozilla/firefox";

    # Home Manager owns ~/.mozilla/native-messaging-hosts, where the 1Password app
    # would otherwise write this itself: lets the extension unlock with the desktop app
    nativeMessagingHosts = [
      (pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/com.1password.1password.json" (
        builtins.toJSON {
          name = "com.1password.1password";
          description = "1Password BrowserSupport";
          path = "/run/wrappers/bin/1Password-BrowserSupport";
          type = "stdio";
          allowed_extensions = [
            "{0a75d802-9aed-41e7-8daa-24c067386e82}"
            "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}"
            "{d634138d-c276-4fc8-924b-40a0ea21d284}"
          ];
        }
      ))
    ];

    policies.ExtensionSettings = lib.mapAttrs' (
      slug: id:
      lib.nameValuePair id {
        installation_mode = "normal_installed"; # installed, but can be disabled
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
      }
    ) extensions;

    # `path` is set per host where a profile with data already exists
    profiles.default = {
      isDefault = true;
      settings = {
        "browser.crashReports.unsubmittedCheck.enabled" = false;
        "browser.disableResetPrompt" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.startup.homepage" = "https://lobste.rs";
        "browser.topsites.blockedSponsors" = ''["amazon"]'';
        "browser.newtabpage.enabled" = true;
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.improvesearch.handoffToAwesomebar" = false;
        "browser.uiCustomization.state" =
          ''{"placements":{"widget-overflow-fixed-list":["ublock0_raymondhill_net-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["developer-button","ublock0_raymondhill_net-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":17,"newElementCount":3}'';
        "browser.uidensity" = 1; # compact
        "browser.bookmarks.showMobileBookmarks" = true;
        "browser.ctrlTab.recentlyUsedOrder" = false;
        "browser.search.hiddenOneOffs" = "Google,Yahoo,Bing,Amazon.com,Twitter";
        "browser.search.region" = "US";
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.placeholderName" = "…";
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.suggest.history" = true;

        # Security and privacy
        "browser.safebrowsing.malware.enabled" = true;
        "browser.safebrowsing.phishing.enabled" = true;
        "browser.send_pings" = false;
        "dom.security.https_only_mode" = true;
        "device.sensors.enabled" = false;
        "dom.battery.enabled" = false;
        "dom.webaudio.enabled" = false;
        "network.dns.disablePrefetch" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "security.ssl.errorReporting.automatic" = false;
        "security.enterprise_roots.enabled" = true;
        "signon.rememberSignons" = false; # the password manager extension does this

        # Firefox Sync off
        "identity.fxaccounts.enabled" = false;

        # Telemetry off
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.updatePing.enabled" = false;

        # Rendering and media
        "gfx.webrender.compositor.force-enabled" = true;
        "layout.css.backdrop-filter.enabled" = true;
        "svg.context-properties.content.enabled" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # userChrome.css
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };
    };
  };
}
