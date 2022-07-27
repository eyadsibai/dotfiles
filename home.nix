{ config, pkgs, nix-colors, ... }: {

  imports = [
    ./apps/terminal/terminal.nix
    ./apps/terminal/shell.nix
    ./apps/terminal/terminal_apps.nix
    ./apps/internet/browsers.nix
    ./apps/programming/editors.nix
    ./apps/utilities/services.nix
    ./apps/internet/social.nix
    ./apps/internet/email.nix
    ./apps/programming/langs.nix
    ./apps/utilities/fonts.nix
    ./apps/wm/i3/i3.nix
    ./apps/office/office.nix
    ./custom_config/default.nix

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
    calcurse
    calibre # e-book reader
    catimg
    cava
    chafa
    clerk
    cli-visualizer
    cmus
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
    git-crypt
    glances
    glow # terminal markdown viewer
    gnomecast # chromecast local files
    gotop
    gtop
    hakuneko
    haxor-news
    highlight
    httpie
    httping
    hyperfine # command-line benchmarking tool
    insomnia # rest client with graphql support
    jitsi-meet-electron # open source video calls and chat
    jmtpfs # mount mtp devices
    jp2a
    khal
    killall # kill processes by name
    libnotify # notify-send command
    libreoffice # office suite
    mc
    mediainfo
    mpc_cli
    mpd-small
    mps-youtube
    mpvScripts.convert
    mpvScripts.mpris
    multilockscreen # fast lockscreen based on i3lock
    mycli
    nano
    nanorc
    ncdu # disk space info (a better du)
    ncpamixer
    neofetch # command-line system information
    nethogs
    nettools
    ngrok # secure tunneling to localhost
    nheko # matrix messaging client
    nitrogen
    nix-index # locate packages containing certain nixpkgs
    nixfmt
    nload
    nyancat # the famous rainbow cat!
    pavucontrol # pulseaudio volume control
    pgcli # modern postgres client
    playerctl # music player controller
    prettyping # a nicer ping
    protonvpn-gui # official proton vpn client
    pulsemixer # pulseaudio mixer
    pyradio
    rainbowstream
    ranger # terminal file explorer
    rclone
    reaverwps-t6x
    ripgrep # fast grep
    rlwrap
    rmlint
    rnix-lsp # nix lsp server
    rsync
    s3cmd
    sc-im
    screenkey
    simple-scan # scanner gui
    simplescreenrecorder # screen recorder gui
    speedtest-cli
    st
    steam
    stig
    sysstat
    tcpdump
    teamviewer
    termdown
    terminal-parrot
    termshark
    thefuck
    tig
    tldr # summary of a man page
    tree # display files in a tree view
    tty-clock
    tuir
    units
    unrar
    unzip
    urlscan
    urlview
    vlc # media player
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
    zip
  ];

  home.enableNixpkgsReleaseCheck = true;
  home.keyboard.layout = "us,ar";
  home.keyboard.options = [ "grp:win_space_toggle" ];

  xsession = {
    enable = true;
    scriptPath = ".hm-xsession";
  };

  programs.gpg.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  news.display = "silent";
  home.stateVersion = "22.05";
  home.sessionVariables = { BROWSER = "/usr/bin/firefox"; };
}
