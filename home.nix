{ config, pkgs, nix-colors, ... }: {

  imports = [
    ./apps/default.nix
    ./apps/wm/i3/default.nix
    ./apps/custom_config/default.nix
  ];

  home.packages = with pkgs; [
    #  gitAndTools.grv
    #  mopidy-spotify
    ack
    ani-cli
    any-nix-shell # fish support for nix shell
    arandr # simple GUI for xrandr
    asciinema
    asciinema # record the terminal
    atool
    audacious # simple music player
    autojump
    aws
    bitwarden
    bitwarden-cli # command-line client for the password manager
    bottom # alternative to htop & ytop
    bpytop
    bridge-utils
    brightnessctl
    cachix # nix caching
    calibre # e-book reader
    catimg
    chafa
    clerk
    cntr
    cobang # qr-code scanner
    cointop
    colorz
    corefonts
    curlFull.dev
    curseofwar
    ddgr
    dialog
    ditaa
    dive # explore docker layers
    drawio # diagram design
    duf # disk usage/free utility
    espeak
    etcher
    exa # a better `ls`
    farbfeld
    fd # "find" for files
    fdupes
    fff
    flatpak
    gcalcli
    gimp # gnu image manipulation program
    glances
    glow # terminal markdown viewer
    gnomecast # chromecast local files
    gotop
    gotty
    gtop
    hakuneko
    highlight
    httpie
    httping
    hyperfine # command-line benchmarking tool
    jmtpfs # mount mtp devices
    jp2a
    killall # kill processes by name
    libnotify # notify-send command
    libreoffice # office suite
    mc
    mediainfo
    mpc_cli
    mpd-small
    mps-youtube
    # mpvScripts.convert
    # mpvScripts.mpris
    multilockscreen # fast lockscreen based on i3lock
    mosh # ssh replacesment
    ncdu # disk space info (a better du)
    ncpamixer
    neofetch # command-line system information
    nethogs
    nettools
    nitrogen
    nix-index # locate packages containing certain nixpkgs
    nixfmt
    nload
    nyancat # the famous rainbow cat!
    pavucontrol # pulseaudio volume control
    playerctl # music player controller
    prettyping # a nicer ping
    protonvpn-gui # official proton vpn client
    pulsemixer # pulseaudio mixer
    ranger # terminal file explorer
    remind
    rclone
    reaverwps-t6x
    ripgrep # fast grep
    rlwrap
    rmlint
    rsync
    sc-im
    screenkey
    simple-scan # scanner gui
    simplescreenrecorder # screen recorder gui
    speedtest-cli
    steam
    stig
    sysstat
    tcpdump
    teamviewer
    teleport
    tmate
    termdown
    termshark
    thefuck
    tldr # summary of a man page
    tree # display files in a tree view
    tty-clock
    units
    unrar
    unzip
    urlscan
    urlview
    w3m
    wavemon
    wget
    wifite2
    wireshark-cli
    wpgtk
    xclip
    xdotool
    xdragon
    xsel # clipboard support (also for neovim)
    xsv
    yad # yet another dialog - fork of zenity
    youtube-dl
    yq
    vdirsyncer
    zip
    zotero
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

      # TODO: doesn't seem to work?
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  news.display = "silent";
  home.stateVersion = "22.05";
  home.sessionVariables = { BROWSER = "/usr/bin/firefox"; };
}
