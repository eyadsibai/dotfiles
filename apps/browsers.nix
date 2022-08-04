{ config, pkgs, ... }:

let addons = pkgs.nur.repos.rycee.firefox-addons;
in {

  home.packages = with pkgs; [ google-chrome pkgs.nur.repos.wolfangaukang.vdhcoapp ];
  # Browsers
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      forceWayland = false;
      extraNativeMessagingHosts = [ pkgs.nur.repos.wolfangaukang.vdhcoapp ];
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
      (buildFirefoxXpiAddon {
        pname = "Video-DownloadHelper";
        version = "7.6.0";
        addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
        url =
          "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-7.6.0-fx.xpi";
        sha256 = "sha256-vVHZwQZOhpogQDAS4BAxm0bvCrcrsz8ioxDdOqsnelM=";
        meta = { };
      })
    ];

    profiles."eyad" = {
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

  programs.chromium = {
    enable = true;
    # package = pkgs.google-chrome;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      {
        id = "dcpihecpambacapedldabdbpakmachpb";
        updateUrl =
          "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml";
      }
    ];
  };

  programs.librewolf = { enable = true; };

  programs.qutebrowser = {
    enable = true;
    settings = {
      colors.webpage.preferred_color_scheme = "dark";
      content.javascript.can_access_clipboard = true;
    };

    keyBindings = {
      normal = {
        # Open videos in mpv
        "<Alt-o>" =
          "hint links spawn --verbose --detach ${pkgs.mpv}/bin/mpv {hint-url}";
        "<Alt-Shift-o>" = "spawn --verbose --detach ${pkgs.mpv}/bin/mpv {url}";
      };
    };

    searchEngines = {
      DEFAULT = "https://www.google.com/search?q={}";
      git = "https://github.com/search?q={}";
      nix = "https://search.nixos.org/packages?query={}&channel=unstable";
      # pip = "https://pypi.org/search/?q={}";
      yt = "https://www.youtube.com/results?search_query={}";
      protondb = "https://www.protondb.com/search?q={}";
      repology = "https://repology.org/projects/?search={}";
    };

    quickmarks = {
      github = "https://github.com";
      github-notifications = "https://github.com/notifications";
      github-gists = "https://gist.github.com";
      nix-manual = "https://nixos.org/manual/nix/unstable";
      nixpkgs = "https://github.com/NixOS/nixpkgs";
      nixpkgs-prs = "https://github.com/NixOS/nixpkgs/pulls";
      nixpkgs-issues = "https://github.com/NixOS/nixpkgs/issues";
      # nixpkgs-tracker = "https://nixpk.gs/pr-tracker.html";
      nixpkgs-manual = "https://nixos.org/manual/nixpkgs/unstable";
      # hydra-trunk = "https://hydra.nixos.org/jobset/nixpkgs/trunk";
      nixos-manual = "https://nixos.org/nixos/manual";
      nixos-options = "https://search.nixos.org/options?channel=unstable";
      home-manager = "https://github.com/nix-community/home-manager";
      home-manager-manual = "https://nix-community.github.io/home-manager";
      home-manager-options =
        "https://rycee.gitlab.io/home-manager/options.html";
      repology = "https://repology.org/projects";
      # dotfiles = "https://github.com/ivarWithoutBones/dotfiles";
      ashley-dotfiles = "https://github.com/kira64xyz/ashley-nix";
      # cppreference = "https://en.cppreference.com/w/cpp";
      protonmail = "https://mail.protonmail.com/inbox";
      nur-actions = "https://github.com/IvarWithoutBones/NUR/actions";
      youtube = "https://www.youtube.com/";
      catan = "https://colonist.io";
    };

    # Apply theme
    extraConfig = builtins.readFile
      (pkgs.fetchurl {
        name = "qutebrowser-dracula-theme.py";
        url =
          "https://raw.githubusercontent.com/dracula/qutebrowser/ba5bd6589c4bb8ab35aaaaf7111906732f9764ef/draw.py";
        sha256 = "sha256-skZYKoB8KSf8VG+5vqlSkg1q7uNZxIY/AizgtPxYyjQ=";
      }) + "blood(c)";
  };
  xdg.configFile."qutebrowser/greasemonkey/youtube-sponsorblock.js".source =
    pkgs.fetchurl {
      name = "qute-youtube-sponsorblock.js";
      url =
        "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_sponsorblock.js";
      sha256 = "sha256-e3QgDPa3AOpPyzwvVjPQyEsSUC9goisjBUDMxLwg8ZE=";
    };

  # Remove ads on YouTube more reliably than with the default adblock
  xdg.configFile."qutebrowser/greasemonkey/youtube-adblock.js".source =
    pkgs.fetchurl {
      name = "qute-youtube-adblock.js";
      url =
        "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_adblock.js";
      sha256 = "sha256-EuGTJ9Am5C6g3MeTsjBQqyNFBiGAIWh+f6cUtEHu3iI=";
    };

  # Dark mode for pages that do not natively support it
  xdg.configFile."qutebrowser/greasemonkey/dark-reader.js".text = ''
    // ==UserScript==
    // @name          Dark Reader (Unofficial)
    // @icon          https://darkreader.org/images/darkreader-icon-256x256.png
    // @namespace     DarkReader
    // @description	  Inverts the brightness of pages to reduce eye strain
    // @version       4.9.52
    // @author        https://github.com/darkreader/darkreader#contributors
    // @homepageURL   https://darkreader.org/ | https://github.com/darkreader/darkreader
    // @run-at        document-end
    // @grant         none
    // @include       http*
    // @exclude       *://*google*.*/*
    // @require       https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js
    // @noframes
    // ==/UserScript==
    DarkReader.enable({
      brightness: 100,
      contrast: 100,
      sepia: 0
    });
  '';
}
