{ config, pkgs, ... }: {

  imports = [
    ./apps/terminal/terminals.nix
    ./apps/terminal/shell.nix
    ./apps/terminal/terminal_tools.nix
    ./apps/internet/browsers.nix
    ./apps/programming/editors.nix
    ./apps/utilities/redshift.nix

  ];

  fonts_pkgs = with pkgs; [ dejavu_fonts fira-code jetbrains-mono ];

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
    pkgs.broot
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
    pkgs.discord
    pkgs.ditaa
    pkgs.dropbox
    pkgs.espeak
    pkgs.etcher
    pkgs.farbfeld
    pkgs.fdupes
    pkgs.fff
    pkgs.flatpak
    pkgs.fzf
    pkgs.gcalcli
    pkgs.git
    pkgs.git-crypt
    pkgs.gitAndTools.tig
    pkgs.gitter
    pkgs.glances
    pkgs.gotop
    pkgs.gtop
    pkgs.haxor-news
    pkgs.highlight
    pkgs.htop
    pkgs.httpie
    pkgs.httping
    pkgs.jetbrains.idea-community
    pkgs.jp2a
    pkgs.jq
    pkgs.khal
    pkgs.lazygit
    pkgs.maven
    pkgs.mc
    pkgs.mediainfo
    pkgs.micro
    pkgs.mopidy
    pkgs.mopidy-mpris
    pkgs.mopidy-soundcloud
    pkgs.mopidy-youtube
    pkgs.mpc_cli
    pkgs.mpd-small
    pkgs.mpdris2
    pkgs.mps-youtube
    pkgs.mpv
    pkgs.mpvScripts.convert
    pkgs.mpvScripts.mpris
    pkgs.mycli
    pkgs.nano
    pkgs.nanorc
    pkgs.ncdu
    pkgs.ncmpcpp
    pkgs.ncpamixer
    pkgs.neofetch
    pkgs.neomutt
    pkgs.neovim
    pkgs.nerdfonts
    pkgs.nethogs
    pkgs.nettools
    pkgs.newsboat
    pkgs.nitrogen
    pkgs.nload
    pkgs.nnn
    pkgs.pavucontrol
    pkgs.pdfgrep
    pkgs.pdftk
    pkgs.pgcli
    pkgs.playerctl
    pkgs.plex-mpv-shim
    pkgs.polybar
    pkgs.pulseaudio
    pkgs.pulseaudio-ctl
    pkgs.pulsemixer
    pkgs.pyradio
    pkgs.pywal
    pkgs.qutebrowser
    pkgs.rclone
    pkgs.reaverwps-t6x
    pkgs.redshift
    pkgs.rlwrap
    pkgs.rmlint
    pkgs.rofi
    pkgs.rofi-emoji
    pkgs.rofi-systemd
    pkgs.rsync
    pkgs.s3cmd
    pkgs.sc-im
    pkgs.screenkey
    pkgs.signal-desktop
    pkgs.skypeforlinux
    pkgs.slack
    pkgs.slack-term
    pkgs.source-code-pro
    pkgs.speedtest-cli
    pkgs.spotify
    pkgs.spotify-tui
    pkgs.st
    pkgs.steam
    pkgs.stig
    pkgs.sxhkd
    pkgs.sxhkd
    pkgs.sysstat
    pkgs.tdesktop
    pkgs.teams
    pkgs.teamviewer
    pkgs.termdown
    pkgs.terminal-parrot
    pkgs.termite
    pkgs.termshark
    pkgs.thefuck
    pkgs.tldr
    pkgs.tmux
    pkgs.tree
    pkgs.tty-clock
    pkgs.tuir
    pkgs.ubuntu_font_family
    pkgs.units
    pkgs.unrar
    pkgs.unzip
    pkgs.urlscan
    pkgs.urlview
    pkgs.w3m
    pkgs.wavemon
    pkgs.wget
    pkgs.whatsapp-for-linux
    pkgs.wifite2
    pkgs.wine
    pkgs.wireshark-cli
    pkgs.wpgtk
    pkgs.xcape
    pkgs.xclip
    pkgs.xdotool
    pkgs.xsv
    pkgs.youtube-dl
    pkgs.yq
    pkgs.zathura
    pkgs.zoom-us

  ] ++ fonts_pkgs;

  # home.username = "e";
  # home.homeDirectory = "$HOME";
  home.enableNixpkgsReleaseCheck = true;
  home.keyboard.layout = "us,ar";
  home.keyboard.options = "grp:win_space_toggle";

  programs.command-not-found.enable = true;

  fonts.fontconfig.enable = true;

  news.display = "silent";
  home.stateVersion = "22.05";
  home.sessionVariables = { BROWSER = "/usr/bin/firefox"; };
}
