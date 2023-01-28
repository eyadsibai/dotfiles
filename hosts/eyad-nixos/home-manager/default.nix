{ inputs
, lib
, pkgs
, config
, outputs
, hostname
, ...
}:
let
  systemConfig = outputs.nixosConfigurations.${hostname}.config;
  inherit (config.colorscheme) colors;
in
{
  imports = [
    ../../common/optional/home-manager/wm/i3
    ../../common/optional/home-manager/kaggle
    ../../common/optional/home-manager/firefox
    ../../common/optional/home-manager/micro
    ../../common/optional/home-manager/flameshot
    ../../common/optional/home-manager/qutebrowser
    ../../common/optional/home-manager/mpv
    ../../common/optional/home-manager/neovim
    ../../common/optional/home-manager/htop
    ../../common/optional/home-manager/nix-index
    ../../common/optional/home-manager/picom
    ../../common/optional/home-manager/newsboat
    ../../common/optional/home-manager/ngrok
    ../../common/optional/home-manager/networkmanager_dmenu
    ../../common/optional/home-manager/kitty
    ../../common/optional/home-manager/spotify
    ../../common/optional/home-manager/menu
    ../../common/optional/home-manager/bitwarden
    ../../common/optional/home-manager/polybar
    ../../common/optional/home-manager/social
    ../../common/optional/home-manager/accounts
    ../../common/optional/home-manager/sxhkd
    ../../common/optional/home-manager/zathura
    ../../common/optional/home-manager/xcape
    ../../common/optional/home-manager/unclutter
    ../../common/optional/home-manager/direnv
    ../../common/optional/home-manager/htop
    ../../common/optional/home-manager/udiskie
    ../../common/optional/home-manager/terminal
    ../../common/optional/home-manager/discord
    ../../common/optional/home-manager/gtk
    ../../common/optional/home-manager/development.nix
    ../../common/optional/home-manager/email_cal_rss.nix
    ../../common/optional/home-manager/media.nix
    ../../common/optional/home-manager/office.nix
    ../../common/optional/home-manager/services.nix
    ../../common/optional/home-manager/system.nix
    ../../common/optional/home-manager/khard
  ];

  home.packages = with pkgs;
    [
      #      whatsie

      lxappearance
      cookiecutter
      git-crypt
      ### PERSONAL
      flakify
      #  gitAndTools.grv
      #  mopidy-spotify
      graphviz
      #ack
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
      # awscli
      awscli2
      bitwarden
      bitwarden-cli
      # command-line client for the password manager
      bridge-utils
      brightnessctl
      # calibre
      # e-book reader
      catimg
      chafa
      # clerk
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
      # ffmpeg_5-full
      # gimp
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
      # teamviewer
      teleport
      termdown
      termshark
      tldr
      # summary of a man page
      tree
      # display files in a tree view
      tty-clock
      units
      urlscan
      urlview
      w3m
      # wavemon
      wget
      # wpgtk
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
      # zotero
      obsidian
      exercism
      peek
      imagemagick
      onionshare
      # nur.repos.wolfangaukang.iptvnator
      # nur.repos.wolfangaukang.sherlock
      # nur.repos.wolfangaukang.nuclear
      yandex-disk
      # upwork
      jrnl
      gparted
      python310Packages.mistune_2_0
      notion-app-enhanced
      statix

      # kepler

      # Terminal
      pfetch # Minimal fetch
      ranger # File Manager

      # Video/Audio
      # plex-media-player
      # stremio #Media Streamer

      # Apps
      remmina

      # File MGMT
      rsync
      unzip
      unrar
      cabextract
      p7zip

      # General Config
      usbutils

      # geogebra6
      # Wayland configuration
      #autotiling       # Tiling Script
      #swayidle         # Idle Management Daemon
      #wev              # Input viewer
      #wl-clipboard     # Console Clipboard

      # Wayland home-manager
      #pamixer          # Pulse Audio Mixer
      #swaylock-fancy   # Screen Locker
      #waybar           # Bar

      # handbrake

      #new-lg4ff        # Logitech Drivers
      #shotcut          # Video editor
      #shotwell         # Raw Image Manager
      #light            # Display Brightness

      hyperfine
      dogdns
      sd
      helix
      k9s
      # jetbrains.pycharm-community
      sherlock
      signal-cli
      signalbackup-tools
      signald
      turses
      twitch-tui
      # block IO monitoring
      iotop
      # per process io rates
      sysstat
      # iostat: per device io rates
      nfs-utils
      # nfsiostat
      ioping
      # disk latencies
      ncdu
      # du but as terminal UI
      # network IO monitoring
      iftop
      # per peer network rates
      # general purpose
      htop
      feh
      # better htop
      # network state
      ethtool
      bpytop
      bottom
      # alternative to htop & ytop (btm)
      gotop
      gtop
      procs

      sxiv

      pgcli
      # modern postgres client
      stable.mycli
      iredis
      usql
      # mathematica

      # lutris
      coursera-dl
      sfeed
      pdfarranger
      pdfslicer
      pdfsam-basic
      pdfmixtool
      meld
      colordiff

      file
      yle-dl

      pdf2svg


      # gksu

      # hdf5


      # dnsutils
      # whois
      # coreutils
      # vbetool
      # killall
      # nethogs
      # binutils
      # lsof
      # usbutils


      # # Gamin: a file and directory monitoring system
      # fam

      # # Basic image manipulation and handling stuff
      # imagemagick
      # ghostscript

      # # SSH filesystem
      # sshfsFuse

      # # Encryption key management
      # gnupg

      # # Yet another dotfile manager

      # gnupg1orig

      # # Password hash generator
      # mkpasswd
      # openssl

      # # Android
      # jmtpfs
      # gphoto2
      # libmtp
      # mtpfs

      # nix-prefetch-git

      # # Make NTFS filesystems (e.g., USB drives)
      # ntfs3g

      # # Encrypted USB sticks etc
      # cryptsetup

      # # GPG password entry from the terminal
      # pinentry


      # # Simple and secure file sending
      # python3Packages.magic-wormhole
      # croc



      # # Printing and scanning
      # simple-scan

      # # Photo/image editor
      # gwenview
      # digikam5
      # gimp-with-plugins

      # # Bluetooth
      # bluedevil


      # # OpenStreetMap editor
      # josm

      # # 3D modelling
      # blender

      # # Zotero client
      # qnotero

      # encfs


      # # E-books
      # fbreader

      # # RSS reader
      # # rssguard
      # #feedreader
      # rssguard

      # w_scan

      # # Audio editor
      # audacity

      # # Screen recorder
      # simplescreenrecorder

      # # MPD client
      # cantata

      # # Panorama stitcher (with raw support)
      # hugin
      # #dcraw # marked as insecure

      # #kdenlive
      # stable.ffmpeg-full
      # # mlt
      # # frei0r

      # # HDR photography
      # luminanceHDR


      # # Encryption
      # openssl

      # # Programming
      # gitAndTools.gitflow
      # gitAndTools.hub


      # # Separate tiling window manager
      # #i3

      # patchelf

      # # Mobile SSH replacement
      # mosh

      # # k3b

      # dvdplusrwtools

      # nixpkgs-review
      # gdb

      # # Break timer
      # stretchly


      # # Screenshots
      # spectacle

      # # Bluetooth
      # bluedevil

      # # Printing and scanning
      # simple-scan
    ]
    ++ (lib.optionals systemConfig.networking.networkmanager.enable [ stable.haskellPackages.network-manager-tui ]);

  home.keyboard.layout = "us,ar";
  home.keyboard.options = [ "grp:win_space_toggle" ];
  xsession = {
    enable = true;
    scriptPath = ".hm-xsession";
  };
  programs.gpg.enable = true;


  services.safeeyes = {
    # enable = true;
  };

  programs.tmate.enable = true;
  programs.pls.enable = true;
  xdg.configFile."yandex-disk/config.cfg" = lib.mkIf (builtins.elem pkgs.yandex-disk config.home.packages) {
    text = ''
      auth="/home/eyad/.config/yandex-disk/passwd"
      dir="/home/eyad/Yandex.Disk"
      proxy="no"
      exclude-dirs="from_mac,photostructure,from_dropbox,audio_books,games,photos,ebooks,Screenshots,papers,movies,videos,visual_computing/ics-502/assignments/assignment1/.direnv,visual_computing/ics-502/assignments/assignment2/.direnv"
    '';
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
    BROWSER = "${pkgs.firefox}/bin/firefox";
    MOZ_USE_XINPUT2 = "1"; # for firefox touchpad support
  };
  # should be in the browsers.nix
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    # ls /usr/share/applications/
    # on nixos:
    #echo $XDG_DATA_DIRS then for each one check /applications/

    "x-schema-handler/msteams" = [ "teams.desktop" ];
    "x-scheme-handler/tg" =
      [ "userapp-Telegram Desktop-8UD5R1.desktop" "userapp-Kotatogram Desktop-CIMGS1.desktop" ];
    "text/html" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" "code.desktop" ];

    "text/csv" = [ "code.desktop" ];
    "text/markdown" = [ "code.desktop" ];
    "text/plain" = [ "code.desktop" ];
    "text/x-python3" = [ "code.desktop" ];
    "text/x-python" = [ "code.desktop" ];
    "text/x-tex" = [ "code.desktop" ];
    "application/x-yaml" = [ "code.desktop" ];
    "application/json" = [ "code.desktop" ];

    "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
    "application/x-gettext-translation" = [ "code.desktop" ];
    "application/x-wine-extension-ini" = [ "code.desktop" ];

    "video/mp4" = [ "mpv.desktop" ];
    "video/ogg" = [ "mpv.desktop" ];
    "video/x-flv" = [ "mpv.desktop" ];
    "video/x-ms-wmv" = [ "mpv.desktop" ];
    "video/x-ogm+ogg" = [ "mpv.desktop" ];
    "video/x-theora+ogg" = [ "mpv.desktop" ];

    "application/x-extension-htm" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "application/x-extension-html" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "application/x-extension-shtml" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "application/x-extension-xht" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "application/x-extension-xhtml" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/chrome" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/ftp" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "application/xhtml+xml" = [ "firefox.desktop" "org.qutebrowser.qutebrowser.desktop" ];
    "audio/x-wav" = [ "mpv.desktop" ];
    "x-scheme-handler/webcal" = [ "firefox.desktop" ];
    "application/xml" = [ "code.desktop" ];
    "x-scheme-handler/mailto" = [ "firefox.desktop" ];

    # "application/zip" = [ "engrampa.desktop" ];
    # "application/octet-stream" = [ "mousepad.desktop" ];
    # "application/x-bittorrent" = [ "deluge.desktop" ];
    # "application/x-ms-dos-executable" = [ "wine.desktop" ];
    "image/gif" = [ "feh.desktop" "viewnior.desktop" "gimp.desktop" ];
    "image/jpeg" = [ "feh.desktop" "viewnior.desktop" "gpicview.desktop" ];
    "image/png" = [ "feh.desktop" "viewnior.desktop" "gpicview.desktop" ];
    # "inode/directory" = [ "pcmanfm.desktop" ];
    # "message/rfc822" = [ "userapp-Thunderbird.desktop" ];
    # "x-scheme-handler/jetbrains" = [ "jetbrains-toolbox.desktop" ];
    # "x-scheme-handler/notion" = [ "notion-app-enhanced.desktop" ];
    # "x-scheme-handler/ssh" = [ "Hyper.desktop" ];
  };

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
  services.kdeconnect = {
    enable = true;
    # package = pkgs.plasma5Packages.kdeconnect-kde;
  };

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

  home.file.".condarc".text = ''
    channels:
      - defaults
      - conda-forge

    always_yes: true

    track_features:
      - nomkl

    auto_activate_base: false
  '';

  xdg.configFile."wget/wgetrc".text = ''
    hsts-file=~/.cache/wget-hsts
  '';

  xdg.configFile."pudb/pudb.cfg".text = ''
    [pudb]
      breakpoints_weight = 1
      current_stack_frame = top
      custom_shell =
      custom_stringifier =
      custom_theme =
      default_variables_access_level = public
      display = auto
      hide_cmdline_win = False
      line_numbers = True
      prompt_on_quit = True
      seen_welcome = e039
      shell = ipython
      sidebar_width = 0.5
      stack_weight = 1
      stringifier = type
      theme = midnight
      variables_weight = 1
      wrap_variables = True
  '';

}
