{ config
, pkgs
, lib
, ...
}:
let
  generateLocalForwards = map (port: {
    bind.port = port;
    host.address = "localhost";
    host.port = port;
  });
in
{
  home.packages = with pkgs; [
    # swaglyrics
    streamlink
    clog-cli
    doing
    # buku
    papis
    timetrap
    timewarrior
    eureka-ideas
    taskell
    nb
    ledger
    ticker
    sent
    bandwhich
    up
    ts
    yank
    yq
    libqalculate
    wego
    translate-shell
    visidata
    dasel
    wp-cli
    http-prompt
  ];
  programs.btop.enable = true;

  services.pueue.enable = pkgs.hostPlatform.isLinux;
  programs.broot = {
    enable = false;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    settings.verbs = [
      {
        invocation = "p";
        execution = ":parent";
      }
      {
        invocation = "edit";
        shortcut = "e";
        execution = "$EDITOR {file}";
      }
      {
        invocation = "create {subpath}";
        execution = "$EDITOR {directory}/{subpath}";
      }
      {
        invocation = "view";
        execution = "less {file}";
      }
      {
        invocation = "blop {name}\\.{type}";
        execution = "/bin/mkdir {parent}/{type} && /usr/bin/nvim {parent}/{type}/{name}.{type}";
        from_shell = true;
      }
    ];
  };
  programs.bat = {
    enable = true;
    config = { pager = "less -FR"; };
    config.theme = "base16";
  };
  # programs.dircolors = {
  #   enable = true;
  #   enableBashIntegration = true;
  #   enableZshIntegration = true;
  #   enableFishIntegration = true;
  # };

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type file --follow";
    # FZF_DEFAULT_COMMAND
    defaultOptions = [ "--height 20%" ];
    # FZF_DEFAULT_OPTS
    fileWidgetCommand = "fd --type file --follow";
    # FZF_CTRL_T_COMMAND
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
  programs.jq = { enable = true; };
  # programs.just = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   enableBashIntegration = true;
  #   enableFishIntegration = true;
  # };
  programs.less = { enable = true; };
  programs.lf = {
    enable = true;
    previewer.source = pkgs.writeShellScript "pv.sh" ''
      #!/bin/sh

      case "$1" in
          *.tar*) tar tf "$1";;
          *.zip) unzip -l "$1";;
          *.rar) unrar l "$1";;
          *.7z) ${pkgs.p7zip}/bin/7z l "$1";;
          *.pdf) ${pkgs.poppler_utils}/bin/pdftotext "$1" -;;
          *) highlight -O ansi "$1" || cat "$1";;
      esac
    '';
  };
  programs.lsd = { enable = true; };
  programs.man = { enable = true; };
  programs.mcfly = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
  programs.navi = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
  programs.ncspot = { enable = true; };
  # programs.command-not-found.enable = true;

  programs.nnn = { enable = true; };
  programs.noti = { enable = true; };
  programs.pandoc = { enable = true; };
  programs.pet = { enable = true; };
  # programs.piston-cli = {
  #   enable = true;
  # };
  # programs.pywal = { enable = false; };

  programs.skim = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
  programs.ssh = {
    enable = true;
    compression = true;
    forwardAgent = false;
    serverAliveCountMax = 10;
    serverAliveInterval = 60;
    extraConfig = ''
      PubkeyAuthentication = yes
      GSSAPIAuthentication = no
      UseRoaming = no
    '';
    matchBlocks = {
      "eyad_pc" = {
        hostname = config.secrets.ssh_config."eyad_pc".hostname;
        user = config.secrets.ssh_config."eyad_pc".user;
        port = config.secrets.ssh_config."eyad_pc".port;
        localForwards = (
          generateLocalForwards
            [
              8989
              7878
              8002
              9117
              8003
              8004
              8181
              9091
              8443
              32400
            ]
        );
      };
      "github" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa";
        identitiesOnly = true;
      };
    };
  };
  programs.taskwarrior = { enable = true; };
  programs.tmux = { enable = true; };
  programs.topgrade = { enable = true; };
  programs.watson = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
  programs.zellij.enable = true;
  programs.zoxide = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
}
