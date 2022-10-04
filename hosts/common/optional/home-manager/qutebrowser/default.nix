{ config
, pkgs
, lib
, ...
}:
let
  inherit (config.colorscheme) colors kind;
in
{
  programs.qutebrowser = {
    enable = true;
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
          preferred_color_scheme = kind;
          bg = "#ffffff";
        };
        completion = {
          fg = "#${colors.base05}";
          match.fg = "#${colors.base09}";
          even.bg = "#${colors.base00}";
          odd.bg = "#${colors.base00}";
          scrollbar = {
            bg = "#${colors.base00}";
            fg = "#${colors.base05}";
          };
          category = {
            bg = "#${colors.base00}";
            fg = "#${colors.base0D}";
            border = {
              bottom = "#${colors.base00}";
              top = "#${colors.base00}";
            };
          };
          item.selected = {
            bg = "#${colors.base02}";
            fg = "#${colors.base05}";
            match.fg = "#${colors.base05}";
            border = {
              bottom = "#${colors.base02}";
              top = "#${colors.base02}";
            };
          };
        };
        contextmenu = {
          disabled = {
            bg = "#${colors.base01}";
            fg = "#${colors.base04}";
          };
          menu = {
            bg = "#${colors.base00}";
            fg = "#${colors.base05}";
          };
          selected = {
            bg = "#${colors.base02}";
            fg = "#${colors.base05}";
          };
        };
        downloads = {
          bar.bg = "#${colors.base00}";
          error.fg = "#${colors.base08}";
          start = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base00}";
          };
          stop = {
            bg = "#${colors.base0C}";
            fg = "#${colors.base00}";
          };
        };
        hints = {
          bg = "#${colors.base0A}";
          fg = "#${colors.base00}";
          match.fg = "#${colors.base05}";
        };
        keyhint = {
          bg = "#${colors.base00}";
          fg = "#${colors.base05}";
          suffix.fg = "#${colors.base05}";
        };
        messages = {
          error.bg = "#${colors.base08}";
          error.border = "#${colors.base08}";
          error.fg = "#${colors.base00}";
          info.bg = "#${colors.base00}";
          info.border = "#${colors.base00}";
          info.fg = "#${colors.base05}";
          warning.bg = "#${colors.base0E}";
          warning.border = "#${colors.base0E}";
          warning.fg = "#${colors.base00}";
        };
        prompts = {
          bg = "#${colors.base00}";
          fg = "#${colors.base05}";
          border = "#${colors.base00}";
          selected.bg = "#${colors.base02}";
        };
        statusbar = {
          caret.bg = "#${colors.base00}";
          caret.fg = "#${colors.base0D}";
          caret.selection.bg = "#${colors.base00}";
          caret.selection.fg = "#${colors.base0D}";
          command.bg = "#${colors.base01}";
          command.fg = "#${colors.base04}";
          command.private.bg = "#${colors.base01}";
          command.private.fg = "#${colors.base0E}";
          insert.bg = "#${colors.base00}";
          insert.fg = "#${colors.base0C}";
          normal.bg = "#${colors.base00}";
          normal.fg = "#${colors.base05}";
          passthrough.bg = "#${colors.base00}";
          passthrough.fg = "#${colors.base0A}";
          private.bg = "#${colors.base00}";
          private.fg = "#${colors.base0E}";
          progress.bg = "#${colors.base0D}";
          url.error.fg = "#${colors.base08}";
          url.fg = "#${colors.base05}";
          url.hover.fg = "#${colors.base09}";
          url.success.http.fg = "#${colors.base0B}";
          url.success.https.fg = "#${colors.base0B}";
          url.warn.fg = "#${colors.base0E}";
        };
        tabs = {
          bar.bg = "#${colors.base00}";
          even.bg = "#${colors.base00}";
          even.fg = "#${colors.base05}";
          indicator.error = "#${colors.base08}";
          indicator.start = "#${colors.base0D}";
          indicator.stop = "#${colors.base0C}";
          odd.bg = "#${colors.base00}";
          odd.fg = "#${colors.base05}";
          pinned.even.bg = "#${colors.base0B}";
          pinned.even.fg = "#${colors.base00}";
          pinned.odd.bg = "#${colors.base0B}";
          pinned.odd.fg = "#${colors.base00}";
          pinned.selected.even.bg = "#${colors.base02}";
          pinned.selected.even.fg = "#${colors.base05}";
          pinned.selected.odd.bg = "#${colors.base02}";
          pinned.selected.odd.fg = "#${colors.base05}";
          selected.even.bg = "#${colors.base02}";
          selected.even.fg = "#${colors.base05}";
          selected.odd.bg = "#${colors.base02}";
          selected.odd.fg = "#${colors.base05}";
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
