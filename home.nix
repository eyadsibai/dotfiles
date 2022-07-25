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
    xsel
    xclip
    any-nix-shell
    ack
    arandr
    asciinema
    atool
    autojump
    aws
    bitwarden
    bitwarden-cli
    calcurse
    catimg
    cava
    chafa
    clerk
    cli-visualizer
    cmus
    cointop
    colorz
    corefonts
    curlFull.dev
    curseofwar
    dive
    cntr
    bridge-utils
    tcpdump
    ddgr
    dialog
    ditaa
    espeak
    etcher
    farbfeld
    fdupes
    fff
    flatpak
    gcalcli
    git-crypt
    gitAndTools.tig
    glances
    gotop
    gtop
    haxor-news
    highlight
    httpie
    httping
    jp2a
    khal
    mc
    mediainfo
    mpc_cli
    mpd-small
    mps-youtube
    mpvScripts.convert
    mpvScripts.mpris
    mycli
    nano
    nanorc
    ncdu
    ncpamixer
    neofetch
    nethogs
    nettools
    nitrogen
    nload
    pavucontrol
    pgcli
    pulsemixer
    pyradio
    rainbowstream
    rclone
    reaverwps-t6x
    rlwrap
    rmlint
    rsync
    s3cmd
    sc-im
    screenkey
    speedtest-cli
    st
    steam
    stig
    sysstat
    teamviewer
    termdown
    terminal-parrot
    termshark
    tig
    thefuck
    tldr
    tree
    tty-clock
    tuir
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
    xsv
    xdragon
    youtube-dl
    yq
    brightnessctl
    nixfmt
    bpytop
  ];

  home.enableNixpkgsReleaseCheck = true;
  home.keyboard.layout = "us,ar";
  home.keyboard.options = [ "grp:win_space_toggle" ];

  xsession = {
    enable = true;
    scriptPath = ".hm-xsession";
  };

  # Nicely reload system units when changing configs
  #  systemd.user.startServices = "sd-switch";

  news.display = "silent";
  home.stateVersion = "22.05";
  home.sessionVariables = { BROWSER = "/usr/bin/firefox"; };
}
