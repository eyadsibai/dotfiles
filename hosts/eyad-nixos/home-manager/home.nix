{ inputs
, lib
, pkgs
, ...
}:
let
  secrets = import ../../../secrets;
in
{
  # inherit secrets;
  imports = [
    ../../common/apps
    ../../common/apps/wm/i3
    ../../common/home-manager

    inputs.nix-doom-emacs.hmModule
    inputs.nix-colors.homeManagerModule
  ];


  home.packages =
    with pkgs;
    [
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
      any-nix-shell
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
      corefonts
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
      ncdu
      # disk space info (a better du)
      ncpamixer
      neofetch
      # command-line system information
      nethogs
      nettools
      nitrogen
      nixpkgs-fmt
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
      comma
      statix
    ];
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
        color = "#ffffff";
        frame_color = "#565d6d";
        separator_color = "#565d6d";
        font = "FiraCode Nerd Font";
      };
      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };
      urgency_low = {
        background = "#2f343f";
        foreground = "#ffffff";
        timeout = 10;
      };
      urgency_normal = {
        background = "#2f343f";
        foreground = "#ffffff";
        timeout = 10;
      };
      urgency_critical = {
        background = "#2f343f";
        foreground = "#ffffff";
        timeout = 10;
      };
    };
  };

  # TODO https://github.com/LukeSmithxyz/voidrice/
  # https://github.com/mitchellh/nixos-config
  # https://github.com/jwiegley/nix-config
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  news.display = "silent";
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
  xdg.userDirs.desktop = "$HOME/desktop";
  xdg.userDirs.documents = "$HOME/documents";
  xdg.userDirs.download = "$HOME/downloads";
  xdg.userDirs.music = "$HOME/music";
  xdg.userDirs.pictures = "$HOME/pictures";
  xdg.userDirs.videos = "$HOME/videos";
  xdg.userDirs.publicShare = "$HOME/public";
  xdg.userDirs.templates = "$HOME/templates";
  # xdg.mimeApps.defaultApplications
  services.kdeconnect.enable = true;



}
