{ config, pkgs, ... }: {

  imports = [
    ./apps/terminal/alacritty.nix
    ./apps/terminal/bash.nix
    ./apps/internet/firefox.nix
    ./apps/programming/vscode.nix
    ./apps/utilities/redshift.nix
  ];

  home.packages = [
    pkgs.google-chrome
    pkgs.wget
    pkgs.atool
    pkgs.httpie
    pkgs.micro
    pkgs.htop
    pkgs.ncpamixer
    pkgs.zoom-us
    pkgs.dropbox
    pkgs.micro
    pkgs.jetbrains.idea-community
    pkgs.slack
    pkgs.bitwarden-cli
    pkgs.sc-im
    pkgs.curlFull.dev
    pkgs.ack
    pkgs.rsync
    pkgs.tmux
    pkgs.jq
    pkgs.st
    pkgs.farbfeld
    pkgs.w3m
    pkgs.xcape
    pkgs.ncdu
    pkgs.espeak
    pkgs.nethogs
    pkgs.sysstat
    pkgs.nload
    pkgs.wavemon
    pkgs.yq
    pkgs.skypeforlinux
    pkgs.haxor-news
    pkgs.cava
    pkgs.spotify
    pkgs.teamviewer
    pkgs.xsv
    pkgs.urlview
    pkgs.urlscan
    pkgs.s3cmd
    pkgs.mycli
    pkgs.pyradio
    pkgs.termshark
    pkgs.slack-term
    pkgs.mopidy-mpris
    pkgs.mopidy-soundcloud
    pkgs.autojump
    pkgs.cawbird
    pkgs.dialog
    pkgs.rofi-emoji
    pkgs.tuir
    pkgs.khal
    pkgs.stig
    pkgs.asciinema
    pkgs.colorz
    pkgs.rmlint
    pkgs.mediainfo
    pkgs.tldr
    pkgs.thefuck
    pkgs.mps-youtube
    pkgs.redshift
    pkgs.tty-clock
    pkgs.clerk
    pkgs.catimg
    pkgs.jp2a
    pkgs.chafa
    pkgs.curseofwar
    pkgs.units
    pkgs.fdupes
    pkgs.arandr
    pkgs.git
    pkgs.gitAndTools.tig
    pkgs.mpv
    pkgs.teams
    pkgs.highlight
    pkgs.nano
    pkgs.nanorc
    pkgs.maven
    pkgs.mopidy-youtube
    pkgs.youtube-dl
    pkgs.mpd-small
    pkgs.ncmpcpp
    pkgs.mopidy
    #    pkgs.mopidy-spotify
    pkgs.rofi
    pkgs.rofi-systemd
    pkgs.nnn
    pkgs.zathura
    pkgs.pdftk
    pkgs.unzip
    pkgs.unrar
    pkgs.fzf
    pkgs.gtop
    pkgs.gotop
    pkgs.fff
    pkgs.mpc_cli
    pkgs.nitrogen
    pkgs.sxhkd
    pkgs.ncpamixer
    pkgs.pavucontrol
    pkgs.pulseaudio
    pkgs.pulseaudio-ctl
    pkgs.mc
    pkgs.steam
    pkgs.screenkey
    pkgs.pywal
    pkgs.wpgtk
    pkgs.polybar
    pkgs.screenkey
    pkgs.sxhkd
    pkgs.bitwarden
    pkgs.oh-my-zsh
    pkgs.cointop
    pkgs.lazygit
    pkgs.pdfgrep
    pkgs.terminal-parrot
    pkgs.qutebrowser
    pkgs.signal-desktop
    pkgs.neomutt
    pkgs.discord
    pkgs.cmus
    pkgs.termite
    pkgs.feh
    pkgs.git-crypt
    pkgs.mpvScripts.mpris
    pkgs.mpvScripts.convert
    pkgs.plex-mpv-shim
    pkgs.kitty
    pkgs.gitter
    pkgs.flatpak
    pkgs.cli-visualizer
    pkgs.tdesktop
    pkgs.brave
    pkgs.ditaa
    pkgs.speedtest-cli
    pkgs.calcurse
    pkgs.neovim
    pkgs.broot
    pkgs.tree
    pkgs.newsboat
    pkgs.wine
    pkgs.xclip
    pkgs.mpdris2
    pkgs.wifite2
    pkgs.reaverwps-t6x
    pkgs.httping
    pkgs.neofetch
    pkgs.xdotool
    pkgs.playerctl
    pkgs.rclone
    pkgs.pgcli
    pkgs.nettools
    pkgs.rlwrap
    pkgs.wireshark-cli
    pkgs.aws
    pkgs.termdown
    pkgs.etcher
    pkgs.gcalcli
    pkgs.spotify-tui
    pkgs.ddgr
    #    pkgs.gitAndTools.grv
    pkgs.glances
    pkgs.pulsemixer
    pkgs.nerdfonts
    pkgs.fira-code
    pkgs.jetbrains-mono
    pkgs.corefonts
    pkgs.dejavu_fonts
    pkgs.source-code-pro
    pkgs.ubuntu_font_family
    pkgs.whatsapp-for-linux

  ];

  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" ];
      theme = "robbyrussell";
    };
  };

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
