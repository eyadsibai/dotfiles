{ inputs
, lib
, pkgs
, config
, outputs
, hostname
, ...
}:
let
  secrets = import ../../../secrets;
  systemConfig = outputs.nixosConfigurations.${hostname}.config;
  inherit (config.colorscheme) colors;


in
{
  # inherit secrets;
  imports = [
    ../../../common/home-manager/wm/i3
    ../../../common/home-manager
    ../../optional/home-manager/kaggle
    ../../optional/home-manager/firefox
    ../../optional/home-manager/micro
    ../../optional/home-manager/flameshot
    ../../optional/home-manager/qutebrowser
    ../../optional/home-manager/mpv
    ../../optional/home-manager/neovim
  ];



  home.packages =
    with pkgs;
    [
      lxappearance
      cookiecutter
      git-crypt
      ### PERSONAL
      flakify
      whatismyip
      #  gitAndTools.grv
      #  mopidy-spotify
      graphviz
      ack
      ani-cli
      # fish support for nix shell
      arandr
      # simple GUI for xrandr
      asciinema
      # record the terminal
      atool
      audacious
      # simple music player
      autojump
      aws
      bitwarden
      bitwarden-cli
      # command-line client for the password manager
      bridge-utils
      brightnessctl
      calibre
      # e-book reader
      catimg
      chafa
      clerk
      cntr
      cobang
      # qr-code scanner
      cointop
      colorz
      # corefonts
      curlFull.dev
      curseofwar
      ddgr
      dialog
      ditaa
      drawio
      # diagram design
      duf
      # disk usage/free utility
      espeak
      etcher
      farbfeld
      fd
      # "find" for files
      fdupes
      fff
      ffmpeg_5-full
      gimp
      # gnu image manipulation program
      glow
      # terminal markdown viewer
      # gnomecast # chromecast local files
      gotty
      hakuneko
      highlight
      httpie
      httping
      hyperfine
      # command-line benchmarking tool
      jmtpfs
      # mount mtp devices
      jp2a
      libnotify
      # notify-send command
      mc
      mediainfo
      mpc_cli
      mpd-small
      multilockscreen
      # fast lockscreen based on i3lock
      mosh
      # ssh replacesment
      ncpamixer
      neofetch
      # command-line system information
      nethogs
      nettools
      nitrogen
      nload
      nyancat
      # the famous rainbow cat!
      pavucontrol
      # pulseaudio volume control
      playerctl
      # music player controller
      prettyping
      # a nicer ping
      protonvpn-gui
      # official proton vpn client
      pulsemixer
      # pulseaudio mixer
      # remind
      rclone
      reaverwps-t6x
      ripgrep
      # fast grep
      rlwrap
      rmlint
      rsync
      sc-im
      screenkey
      simple-scan
      # scanner gui
      simplescreenrecorder
      # screen recorder gui
      speedtest-cli
      stig
      sysstat
      tcpdump
      teamviewer
      teleport
      tmate
      termdown
      termshark
      thefuck
      tldr
      # summary of a man page
      tree
      # display files in a tree view
      tty-clock
      units
      unrar
      unzip
      urlscan
      urlview
      w3m
      wavemon
      wget
      wpgtk
      xclip
      xdotool
      xdragon
      xsel
      # clipboard support (also for neovim)
      xsv
      yad
      # yet another dialog - fork of zenity
      yq
      vdirsyncer
      zip
      zotero
      obsidian
      exercism
      peek
      imagemagick
      onionshare
      # nur.repos.wolfangaukang.iptvnator
      # nur.repos.wolfangaukang.sherlock
      nur.repos.wolfangaukang.nuclear
      yandex-disk
      # upwork
      jrnl
      gparted
      python310Packages.mistune_2_0
      notion-app-enhanced
      statix

      # kepler

      # Terminal
      btop # Resource Manager
      pfetch # Minimal fetch
      ranger # File Manager

      # Video/Audio
      plex-media-player
      stremio #Media Streamer


      # Apps
      remmina

      # File MGMT
      rsync
      unzip
      unrar

      # General Config
      usbutils

      # Wayland configuration
      #autotiling       # Tiling Script
      #swayidle         # Idle Management Daemon
      #wev              # Input viewer
      #wl-clipboard     # Console Clipboard

      # Wayland home-manager
      #pamixer          # Pulse Audio Mixer
      #swaylock-fancy   # Screen Locker
      #waybar           # Bar

      handbrake

      #new-lg4ff        # Logitech Drivers
      #shotcut          # Video editor
      #shotwell         # Raw Image Manager
      #light            # Display Brightness

      hyperfine
      dogdns
      sd
      kakoune
      helix
      k9s
      yt-dlp
      # jetbrains.pycharm-community
      sherlock
      signal-cli
      signalbackup-tools
      signald
      turses
      twitch-tui
    ]
    ++ (lib.optionals systemConfig.networking.networkmanager.enable [ haskellPackages.network-manager-tui ]);
  home.enableNixpkgsReleaseCheck = true;
  home.keyboard.layout = "us,ar";
  home.keyboard.options = [ "grp:win_space_toggle" ];
  xsession = {
    enable = true;
    scriptPath = ".hm-xsession";
  };
  programs.gpg.enable = true;
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "keyboard";
        indicate_hidden = "yes";
        shrink = "yes";
        transparency = 10;
        notification_height = 0;
        separator_height = 2;
        padding = 0;
        horizontal_padding = 8;
        frame_width = 3;
        geometry = "350x5-0+24";
        sort = "yes";
        idle_threshold = 120;
        line_height = 0;
        markup = "full";
        alignment = "left";
        show_age_threshold = "60";
        word_wrap = "yes";
        ellipsize = "middle";
        ignore_newline = "no";
        stack_duplicates = "true";
        hide_duplicate_count = "true";
        show_indicators = "yes";
        icon_position = "left";
        max_icon_size = "40";
        format = "<b>%s</b>\n%b";
        color = "#${colors.base00}";
        frame_color = "#${colors.base03}";
        separator_color = "#${colors.base03}";
        font = "${config.fontProfiles.regular.family} 12";
        sticky_history = "yes";
        history_length = 20;
        dmenu = "${config.home.preferredApps.menu.dmenu-cmd}";
        browser = "/usr/bin/brave -new-tab"; # TODO
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        startup_notification = false;
        force_xinerama = true;
      };
      experimental = {
        per_monitor_dpi = true;
      };
      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };
      urgency_low = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
        timeout = 10;
      };
      urgency_normal = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
        timeout = 10;
      };
      urgency_critical = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
        timeout = 10;
      };
    };
  };

  # TODO https://github.com/LukeSmithxyz/voidrice/
  # https://github.com/mitchellh/nixos-config
  # https://github.com/jwiegley/nix-config
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  # news.display = "silent";
  home.stateVersion = "22.05";
  home.sessionVariables = rec {
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    XDG_DATA_HOME = "\${HOME}/.local/share";
    # PATH = [
    #   "\${XDG_BIN_HOME}"
    # ];
    BROWSER = "${ pkgs.firefox }/bin/firefox";
    MOZ_USE_XINPUT2 = "1"; # for firefox touchpad support
  };
  # should be in the browsers.nix
  # xdg.mimeApps.enable = true;
  xdg.userDirs = {
    desktop = "$HOME/desktop";
    documents = "$HOME/documents";
    download = "$HOME/downloads";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    videos = "$HOME/videos";
    publicShare = "$HOME/public";
    templates = "$HOME/templates";
  };
  # xdg.mimeApps.defaultApplications
  services.kdeconnect.enable = true;

  home.preferredApps = {
    menu = {
      run-cmd = "rofi -show run";
      drun-cmd = "rofi -show drun";
      dmenu-cmd = "rofi -dmenu";
      password-cmd = "rofi-rbw";
    };


    terminal = {
      cmd = "kitty -1";
      cmd-spawn = program: "kitty -1 $SHELL -i -c ${program}";
    };

    mail = {
      cmd = config.home.preferredApps.terminal.cmd-spawn "neomutt";
    };
    browser = {
      cmd = "qutebrowser";
    };

    notifier = {
      cmd = "";
    };
    editor = {
      cmd = "";
    };
  };
}
