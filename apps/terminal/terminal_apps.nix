{ pkgs, ... }: {
  home.packages = with pkgs; [
    swaglyrics
    streamlink
    clog-cli
    doing
    buku
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

  programs.broot = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
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
    themes = {
      dracula = builtins.readFile (pkgs.fetchFromGitHub
        {
          owner = "dracula";
          repo = "sublime"; # Bat uses sublime syntax for its themes
          rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
          sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
        }
      + "/Dracula.tmTheme");
    };
  };

  programs.feh = {
    enable = true;
    keybindings = {
      menu_parent = "h Left";
      menu_child = "l";
      menu_down = "j";
      menu_up = "k";
      menu_select = "space";
    };
  };

  # programs.dircolors = {
  #   enable = true;
  #   enableBashIntegration = true;
  #   enableZshIntegration = true;
  #   enableFishIntegration = true;
  # };

  programs.direnv = {
    enable = true;
    nix-direnv = { enable = true; };
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
  };

  programs.exa = {
    # better 'ls'
    enable = true;
    enableAliases = true;
  };

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type file --follow"; # FZF_DEFAULT_COMMAND
    defaultOptions = [ "--height 20%" ]; # FZF_DEFAULT_OPTS
    fileWidgetCommand = "fd --type file --follow"; # FZF_CTRL_T_COMMAND
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
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
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.navi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
  };

  programs.ncspot = { enable = true; };

  # programs.command-not-found.enable = true;
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
  };

  home.file.".cache/nix-index".source = pkgs.nix-index-database;

  programs.nnn = { enable = true; };

  programs.noti = { enable = true; };

  programs.pandoc = { enable = true; };

  programs.pet = { enable = true; };

  # programs.piston-cli = {
  #   enable = true;
  # };

  # programs.pywal = { enable = false; };

  programs.rbw = {
    enable = true;
    settings = {
      email = "eyad.alsibai@gmail.com";
      lock_timeout = 172800;
      pinentry = "tty";
    };
  };

  programs.skim = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
  };

  programs.ssh = { enable = true; };

  # programs.starship = { enable = true; };

  programs.taskwarrior = { enable = true; };

  programs.tmux = { enable = true; };

  programs.topgrade = { enable = true; };

  programs.watson = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
  };

  programs.zellij.enable = true;

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false;
  };
}
