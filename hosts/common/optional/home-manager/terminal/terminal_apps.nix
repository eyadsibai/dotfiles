{ config
, pkgs
, ...
}:
# assert config.programs.bash.enable;
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
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    verbs = [
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
  programs.lf = { enable = true; };
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
  programs.ssh = { enable = true; };
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
