{ config
, pkgs
, lib
, ...
}:
let
  inherit (config.colorscheme) palette variant;
in
{
  programs.qutebrowser = {
    enable = true;
    # package = pkgs.stable.qutebrowser;

    loadAutoconfig = true;
    settings = {
      downloads = {
        location.remember = true;
        position = "bottom";
      };
      new_instance_open_target = "window";
      content.javascript.can_access_clipboard = true;
      search.incremental = false;
      content = {
        blocking.hosts.lists = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
        blocking.method = "both";
        blocking.adblock.lists = [
          "https://easylist.to/easylist/easylist.txt"
          "https://easylist.to/easylist/easyprivacy.txt"
          "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt"
          "https://easylist.to/easylist/fanboy-annoyance.txt"
          "https://secure.fanboy.co.nz/fanboy-annoyance.txt"
          "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt"
          "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt"
          "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"
          "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt"
          "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt"
          "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt"
          "https://www.i-dont-care-about-cookies.eu/abp/"
        ];
        pdfjs = true;
        plugins = true;
        print_element_backgrounds = false;
        fullscreen.window = true;

      };
      confirm_quit = [ "multiple-tabs" ];
      auto_save = {
        interval = 10000;
        session = true;

      };
      tabs = {
        show = "multiple";
        position = "left";
        background = true;
      };
      fonts = {
        default_family = config.fontProfiles.regular.family;
        default_size = "12pt";
        tabs.selected = "8pt ${config.fontProfiles.monospace.family}";
        tabs.unselected = "8pt ${config.fontProfiles.monospace.family}";
        statusbar = "8pt ${config.fontProfiles.monospace.family}";
        web.family.fantasy = config.fontProfiles.regular.family;
      };
      colors = {
        webpage = {
          preferred_color_scheme = "dark";
          bg = "#ffffff";
        };
        completion = {
          fg = "#${palette.base05}";
          match.fg = "#${palette.base09}";
          even.bg = "#${palette.base00}";
          odd.bg = "#${palette.base00}";
          scrollbar = {
            bg = "#${palette.base00}";
            fg = "#${palette.base05}";
          };
          category = {
            bg = "#${palette.base00}";
            fg = "#${palette.base0D}";
            border = {
              bottom = "#${palette.base00}";
              top = "#${palette.base00}";
            };
          };
          item.selected = {
            bg = "#${palette.base02}";
            fg = "#${palette.base05}";
            match.fg = "#${palette.base05}";
            border = {
              bottom = "#${palette.base02}";
              top = "#${palette.base02}";
            };
          };
        };
        contextmenu = {
          disabled = {
            bg = "#${palette.base01}";
            fg = "#${palette.base04}";
          };
          menu = {
            bg = "#${palette.base00}";
            fg = "#${palette.base05}";
          };
          selected = {
            bg = "#${palette.base02}";
            fg = "#${palette.base05}";
          };
        };
        downloads = {
          bar.bg = "#${palette.base00}";
          error.fg = "#${palette.base08}";
          start = {
            bg = "#${palette.base0D}";
            fg = "#${palette.base00}";
          };
          stop = {
            bg = "#${palette.base0C}";
            fg = "#${palette.base00}";
          };
        };
        hints = {
          bg = "#${palette.base0A}";
          fg = "#${palette.base00}";
          match.fg = "#${palette.base05}";
        };
        keyhint = {
          bg = "#${palette.base00}";
          fg = "#${palette.base05}";
          suffix.fg = "#${palette.base05}";
        };
        messages = {
          error.bg = "#${palette.base08}";
          error.border = "#${palette.base08}";
          error.fg = "#${palette.base00}";
          info.bg = "#${palette.base00}";
          info.border = "#${palette.base00}";
          info.fg = "#${palette.base05}";
          warning.bg = "#${palette.base0E}";
          warning.border = "#${palette.base0E}";
          warning.fg = "#${palette.base00}";
        };
        prompts = {
          bg = "#${palette.base00}";
          fg = "#${palette.base05}";
          border = "#${palette.base00}";
          selected.bg = "#${palette.base02}";
        };
        statusbar = {
          caret.bg = "#${palette.base00}";
          caret.fg = "#${palette.base0D}";
          caret.selection.bg = "#${palette.base00}";
          caret.selection.fg = "#${palette.base0D}";
          command.bg = "#${palette.base01}";
          command.fg = "#${palette.base04}";
          command.private.bg = "#${palette.base01}";
          command.private.fg = "#${palette.base0E}";
          insert.bg = "#${palette.base00}";
          insert.fg = "#${palette.base0C}";
          normal.bg = "#${palette.base00}";
          normal.fg = "#${palette.base05}";
          passthrough.bg = "#${palette.base00}";
          passthrough.fg = "#${palette.base0A}";
          private.bg = "#${palette.base00}";
          private.fg = "#${palette.base0E}";
          progress.bg = "#${palette.base0D}";
          url.error.fg = "#${palette.base08}";
          url.fg = "#${palette.base05}";
          url.hover.fg = "#${palette.base09}";
          url.success.http.fg = "#${palette.base0B}";
          url.success.https.fg = "#${palette.base0B}";
          url.warn.fg = "#${palette.base0E}";
        };
        tabs = {
          bar.bg = "#${palette.base00}";
          even.bg = "#${palette.base00}";
          even.fg = "#${palette.base05}";
          indicator.error = "#${palette.base08}";
          indicator.start = "#${palette.base0D}";
          indicator.stop = "#${palette.base0C}";
          odd.bg = "#${palette.base00}";
          odd.fg = "#${palette.base05}";
          pinned.even.bg = "#${palette.base0B}";
          pinned.even.fg = "#${palette.base00}";
          pinned.odd.bg = "#${palette.base0B}";
          pinned.odd.fg = "#${palette.base00}";
          pinned.selected.even.bg = "#${palette.base02}";
          pinned.selected.even.fg = "#${palette.base05}";
          pinned.selected.odd.bg = "#${palette.base02}";
          pinned.selected.odd.fg = "#${palette.base05}";
          selected.even.bg = "#${palette.base02}";
          selected.even.fg = "#${palette.base05}";
          selected.odd.bg = "#${palette.base02}";
          selected.odd.fg = "#${palette.base05}";
        };
      };
    };
    aliases = {
      paywall = "open https://12ft.io/proxy?q={url}";
      google-cache = "open https://www.google.com/search?q=cache:{url}";
      google = "open https://google.com/";
    };
    keyBindings = {
      normal = {
        # Open videos in mpv
        "<Alt-o>" = "hint links spawn --verbose --detach ${pkgs.mpv}/bin/mpv {hint-url}";
        "<Alt-Shift-o>" = "spawn --verbose --detach ${pkgs.mpv}/bin/mpv {url}";
        "m" = "spawn umpv {url}";
        "M" = "hint links spawn umpv {hint-url}";
        ";M" = "hint --rapid links spawn umpv {hint-url}";
        ",p" = "config-cycle -p content.plugins ;; reload";
        ",rtv" = "spawn termite -e \"rtv {url}\" ";
        ",c" = "spawn -d firefox {url}";
        # css from https://github.com/alphapapa/solarized-everything-css.git
        ",n" =
          "config-cycle content.user_stylesheets ~/.config/qutebrowser/css/solarized-dark-all-sites.css ~/.config/qutebrowser/css/gruvbox-all-sites.css ~/.config/qutebrowser/css/darculized-all-sites.css \"\" ";
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
      duckduckgo = "https://duckduckgo.com/?q={}";
      "w" = "https://en.wikipedia.org/?search={}";
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
      home-manager-options = "https://rycee.gitlab.io/home-manager/options.html";
      repology = "https://repology.org/projects";
      # dotfiles = "https://github.com/ivarWithoutBones/dotfiles";
      ashley-dotfiles = "https://github.com/kira64xyz/ashley-nix";
      # cppreference = "https://en.cppreference.com/w/cpp";
      protonmail = "https://mail.protonmail.com/inbox";
      nur-actions = "https://github.com/IvarWithoutBones/NUR/actions";
      youtube = "https://www.youtube.com/";
      catan = "https://colonist.io";
    };

    extraConfig = ''
      c.tabs.padding = {"bottom": 10, "left": 10, "right": 10, "top": 10}
    '';
  };
  xdg.configFile."qutebrowser/greasemonkey/youtube-sponsorblock.js" = lib.mkIf config.programs.qutebrowser.enable {
    source =
      pkgs.fetchurl
        {
          name = "qute-youtube-sponsorblock.js";
          url = "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_sponsorblock.js";
          sha256 = "sha256-e3QgDPa3AOpPyzwvVjPQyEsSUC9goisjBUDMxLwg8ZE=";
        };
  };
  # Remove ads on YouTube more reliably than with the default adblock
  xdg.configFile."qutebrowser/greasemonkey/youtube-adblock.js" = lib.mkIf config.programs.qutebrowser.enable {
    source =
      pkgs.fetchurl
        {
          name = "qute-youtube-adblock.js";
          url = "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_adblock.js";
          sha256 = "sha256-EuGTJ9Am5C6g3MeTsjBQqyNFBiGAIWh+f6cUtEHu3iI=";
        };
  };
  # Dark mode for pages that do not natively support it
  # xdg.configFile."qutebrowser/greasemonkey/dark-reader.js".text =
  #   ''
  #     // ==UserScript==
  #     // @name          Dark Reader (Unofficial)
  #     // @icon          https://darkreader.org/images/darkreader-icon-256x256.png
  #     // @namespace     DarkReader
  #     // @description    Inverts the brightness of pages to reduce eye strain
  #     // @version       4.9.52
  #     // @author        https://github.com/darkreader/darkreader#contributors
  #     // @homepageURL   https://darkreader.org/ | https://github.com/darkreader/darkreader
  #     // @run-at        document-end
  #     // @grant         none
  #     // @include       http*
  #     // @exclude       *://*google*.*/*
  #     // @require       https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js
  #     // @noframes
  #     // ==/UserScript==
  #     DarkReader.enable({
  #       brightness: 100,
  #       contrast: 100,
  #       sepia: 0
  #     });
  #   '';
}
