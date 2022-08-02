{ pkgs, ... }:

{

  programs.micro = {
    enable = true;

  };
  home.packages = with pkgs; [
    jetbrains.idea-community
    atom
    nano
    nanorc
    s3cmd
    # awscli2 # TODO crash on install
    tig
    ngrok # secure tunneling to localhost
    insomnia # rest client with graphql support
    beekeeper-studio
    vscode
    earthly
    t-rec
    reviewdog
    # pgcli # modern postgres client # TODO crash on install
    mycli
    iredis
    usql
  ];
  # programs.go = { enable = true; };
  # programs.java = { enable = true; };
  # programs.sbt = { enable = true; };
  programs.vscode = {
    enable = false;
    # extensions = with pkgs.vscode-extensions;
    # [
    # dracula-theme.theme-dracula
    # vscodevim.vim
    # yzhang.markdown-all-in-one
    # golang.go
    # ms-python.python
    # eamodio.gitlens
    # christian-kohler.path-intellisense
    # ms-vscode-remote.remote-ssh
    # ms-vsliveshare.vsliveshare
    # jnoortheen.nix-ide
    # ];
    # userSettings = { "update.channel" = "none"; };
  };

  programs.helix = {
    enable = true;
    languages = [
      {
        auto-format = false;
        name = "rust";
      }
      { name = "python"; }
    ];
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.doom-emacs = {
    enable = true;
    doomPrivateDir = ./custom_config/doom-emacs;
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
  programs.lazygit = { enable = true; };

}
