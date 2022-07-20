{ pkgs, ... }: {

  programs.htop = { enable = true; };

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
        execution =
          "/bin/mkdir {parent}/{type} && /usr/bin/nvim {parent}/{type}/{name}.{type}";
        from_shell = true;
      }
    ];

  };

  programs.bat = {
    enable = true;
    config = { pager = "less -FR"; };
    themes = {
      dracula = builtins.readFile (pkgs.fetchFromGitHub {
        owner = "dracula";
        repo = "sublime"; # Bat uses sublime syntax for its themes
        rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
        sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
      } + "/Dracula.tmTheme");
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

  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    # enableFishIntegration = true;
  };

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.gh = {
    enable = true;
    enableGitCredentialHelper = true;
    settings = {
      git_protocol = "ssh";

      prompt = "enabled";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  programs.git = {
    enable = true;

    # diff tool
    delta = { enable = true; };
    attributes = [
      "* text=auto"
      "*.sh text eol=lf"
      "*.7z filter=lfs diff=lfs merge=lfs -text"
      "*.br filter=lfs diff=lfs merge=lfs -text"
      "*.gz filter=lfs diff=lfs merge=lfs -text"
      "*.tar filter=lfs diff=lfs merge=lfs -text"
      "*.zip filter=lfs diff=lfs merge=lfs -text"

      "*.pdf filter=lfs diff=lfs merge=lfs -text"
      "*.gif filter=lfs diff=lfs merge=lfs -text"
      "*.ico filter=lfs diff=lfs merge=lfs -text"
      "*.jpg filter=lfs diff=lfs merge=lfs -text"
      "*.pdf filter=lfs diff=lfs merge=lfs -text"
      "*.png filter=lfs diff=lfs merge=lfs -text"
      "*.psd filter=lfs diff=lfs merge=lfs -text"
      "*.webp filter=lfs diff=lfs merge=lfs -text"
      "*.woff2 filter=lfs diff=lfs merge=lfs -text"
      "*.exe filter=lfs diff=lfs merge=lfs -text"
    ];

    # diff tool
    # diff-so-fancy = {
    #   enable = true;
    # };

    # diff tool
    # difftastic = {
    #   enable = true;
    # };

    lfs = { enable = true; };
  };

  programs.gitui = { enable = true; };

  programs.jq = { enable = true; };

  programs.just = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.lazygit = { enable = true; };

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

  programs.micro = {
    enable = true;

  };

  programs.mpv = { enable = true; };

  programs.navi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.ncmpcpp = { enable = true; };

  programs.ncspot = { enable = true; };

  # programs.command-not-found.enable = true;
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.nnn = { enable = true; };

  programs.noti = { enable = true; };

  programs.pandoc = { enable = true; };

  programs.pet = { enable = true; };

  # programs.piston-cli = {
  #   enable = true;
  # };

  programs.pywal = { enable = true; };

  programs.rbw = { enable = true; };

  programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-calc ];
  };

  programs.skim = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.ssh = { enable = true; };

  programs.starship = { enable = true; };

  programs.taskwarrior = { enable = true; };

  programs.tmux = { enable = true; };

  programs.topgrade = { enable = true; };

  programs.watson = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.zellij.enable = true;

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

  };

}
