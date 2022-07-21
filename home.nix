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

  ];

  home.packages = [
    #    pkgs.gitAndTools.grv
    #    pkgs.mopidy-spotify
    pkgs.ack
    pkgs.arandr
    pkgs.asciinema
    pkgs.atool
    pkgs.autojump
    pkgs.aws
    pkgs.bitwarden
    pkgs.bitwarden-cli
    pkgs.brave
    pkgs.calcurse
    pkgs.catimg
    pkgs.cava
    pkgs.cawbird
    pkgs.chafa
    pkgs.clerk
    pkgs.cli-visualizer
    pkgs.cmus
    pkgs.cointop
    pkgs.colorz
    pkgs.corefonts
    pkgs.curlFull.dev
    pkgs.curseofwar
    pkgs.ddgr
    pkgs.dialog
    pkgs.ditaa
    pkgs.espeak
    pkgs.etcher
    pkgs.farbfeld
    pkgs.fdupes
    pkgs.fff
    pkgs.flatpak
    pkgs.gcalcli
    pkgs.git-crypt
    pkgs.gitAndTools.tig
    pkgs.gitter
    pkgs.glances
    pkgs.gotop
    pkgs.gtop
    pkgs.haxor-news
    pkgs.highlight
    pkgs.httpie
    pkgs.httping
    pkgs.jp2a
    pkgs.khal
    pkgs.maven
    pkgs.mc
    pkgs.mediainfo
    pkgs.mpc_cli
    pkgs.mpd-small
    pkgs.mps-youtube
    pkgs.mpvScripts.convert
    pkgs.mpvScripts.mpris
    pkgs.mycli
    pkgs.nano
    pkgs.nanorc
    pkgs.ncdu
    pkgs.ncpamixer
    pkgs.neofetch
    pkgs.nethogs
    pkgs.nettools
    pkgs.nitrogen
    pkgs.nload
    pkgs.pavucontrol
    pkgs.pdfgrep
    pkgs.pdftk
    pkgs.pgcli
    pkgs.pulseaudio
    pkgs.pulseaudio-ctl
    pkgs.pulsemixer
    pkgs.pyradio
    pkgs.rainbowstream
    pkgs.rclone
    pkgs.reaverwps-t6x
    pkgs.rlwrap
    pkgs.rmlint
    pkgs.rsync
    pkgs.s3cmd
    pkgs.sc-im
    pkgs.screenkey
    pkgs.speedtest-cli
    pkgs.spotify
    pkgs.spotify-tui
    pkgs.st
    pkgs.steam
    pkgs.stig
    pkgs.sysstat
    pkgs.teamviewer
    pkgs.termdown
    pkgs.terminal-parrot
    pkgs.termshark
    pkgs.tig
    pkgs.thefuck
    pkgs.tldr
    pkgs.tree
    pkgs.tty-clock
    pkgs.tuir
    pkgs.units
    pkgs.unrar
    pkgs.unzip
    pkgs.urlscan
    pkgs.urlview
    pkgs.w3m
    pkgs.wavemon
    pkgs.wget
    pkgs.wifite2
    pkgs.wine
    pkgs.wireshark-cli
    pkgs.wpgtk
    pkgs.xclip
    pkgs.xdotool
    pkgs.xsv
    pkgs.xdragon
    pkgs.youtube-dl
    pkgs.yq

  ];

  home.enableNixpkgsReleaseCheck = true;
  home.keyboard.layout = "us,ar";
  home.keyboard.options = "grp:win_space_toggle";

  # home.file.".ackrc".source = ./files/.ackrc;
  home.file.".ackrc".source =
    config.lib.file.mkOutOfStoreSymlink ./files/.ackrc;

  # Nicely reload system units when changing configs
  #  systemd.user.startServices = "sd-switch";

  news.display = "silent";
  home.stateVersion = "22.05";
  home.sessionVariables = { BROWSER = "/usr/bin/firefox"; };
}
